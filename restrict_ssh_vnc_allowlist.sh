#!/usr/bin/env bash
# Restrict SSH and VNC (5901/5902) to an IP/CIDR allowlist on Ubuntu 24.04.
#
# Usage:
#   sudo bash restrict_ssh_vnc_allowlist.sh
#   sudo bash restrict_ssh_vnc_allowlist.sh /path/to/allowed_ips.txt
#
# The optional file must contain one IPv4/IPv6 address or CIDR per line.
# Blank lines and lines beginning with "#" are ignored.

set -Eeuo pipefail
umask 077

readonly PROGRAM_NAME="${0##*/}"
readonly TABLE_NAME="ssh_vnc_allowlist"
readonly CONFIG_DIR="/etc/ssh-vnc-allowlist"
readonly ALLOWLIST_FILE="${CONFIG_DIR}/allowed_sources.txt"
readonly NFT_DIR="/etc/nftables.d"
readonly NFT_RULE_FILE="${NFT_DIR}/${TABLE_NAME}.nft"
readonly SERVICE_NAME="ssh-vnc-allowlist.service"
readonly SERVICE_FILE="/etc/systemd/system/${SERVICE_NAME}"
readonly BACKUP_ROOT="/var/backups/ssh-vnc-allowlist"
readonly UFW_COMMENT="ssh-vnc-allowlist"

TEMP_DIR=""
BACKUP_DIR=""

die() {
  printf '错误：%s\n' "$*" >&2
  exit 1
}

info() {
  printf '[%s] %s\n' "$PROGRAM_NAME" "$*"
}

cleanup() {
  if [[ -n "$TEMP_DIR" && -d "$TEMP_DIR" ]]; then
    rm -rf -- "$TEMP_DIR"
  fi
}
trap cleanup EXIT

[[ ${EUID} -eq 0 ]] || die "请使用 sudo bash $PROGRAM_NAME 运行。"
[[ $# -le 1 ]] || die "用法：sudo bash $PROGRAM_NAME [IP白名单文件]"
command -v systemctl >/dev/null 2>&1 || die "当前系统不是 systemd 环境。"

TEMP_DIR="$(mktemp -d -t ssh-vnc-allowlist.XXXXXX)"
RAW_ALLOWLIST="${TEMP_DIR}/raw_allowlist.txt"
NORMALIZED_ALLOWLIST="${TEMP_DIR}/normalized_allowlist.txt"

if [[ $# -eq 1 ]]; then
  [[ -f "$1" && -r "$1" ]] || die "无法读取白名单文件：$1"
  cp -- "$1" "$RAW_ALLOWLIST"
else
  # 来自用户上传文件的白名单；重复项已在安装时自动去重。
  cat >"$RAW_ALLOWLIST" <<'ALLOWLIST'
10.122.161.210
10.122.161.210
10.122.161.197
10.122.161.197
10.122.161.208
10.122.161.208
10.122.161.19
10.122.161.19
10.122.161.142
10.122.161.142
10.122.161.156
10.122.161.156
10.122.161.49
10.122.161.49
10.122.150.58
10.122.150.58
10.122.161.18
10.122.161.18
10.122.150.187
10.122.150.187
10.122.5.95
10.122.5.97
10.100.82.83
ALLOWLIST
fi

command -v python3 >/dev/null 2>&1 || die "缺少 python3；Ubuntu 24.04 默认应已安装。"

# 严格解析、规范化、去重并移除被更大网段包含的项；拒绝 0.0.0.0/0 和 ::/0。
python3 - "$RAW_ALLOWLIST" >"$NORMALIZED_ALLOWLIST" <<'PY'
import ipaddress
import pathlib
import sys

path = pathlib.Path(sys.argv[1])
networks = {4: [], 6: []}

for line_no, raw in enumerate(path.read_text(encoding="utf-8-sig").splitlines(), 1):
    value = raw.split("#", 1)[0].strip()
    if not value:
        continue
    if value.startswith("- "):
        value = value[2:].strip()
    try:
        network = ipaddress.ip_network(value, strict=False)
    except ValueError as exc:
        raise SystemExit(f"白名单第 {line_no} 行无效：{value!r}（{exc}）")
    if network.prefixlen == 0:
        raise SystemExit(f"白名单第 {line_no} 行禁止使用全网段：{value!r}")
    networks[network.version].append(network)

normalized = []
for version in (4, 6):
    # 先处理大网段；只移除重复/被包含项，不把相邻的独立主机合并成网段。
    candidates = sorted(set(networks[version]), key=lambda n: (n.prefixlen, int(n.network_address)))
    retained = []
    for network in candidates:
        if not any(network.subnet_of(existing) for existing in retained):
            retained.append(network)
    normalized.extend(sorted(retained, key=lambda n: (int(n.network_address), n.prefixlen)))

if not normalized:
    raise SystemExit("白名单为空，已拒绝修改防火墙。")

for network in normalized:
    host_prefix = 32 if network.version == 4 else 128
    value = str(network.network_address) if network.prefixlen == host_prefix else network.with_prefixlen
    print(f"{network.version}|{value}")
PY

mapfile -t IPV4_SOURCES < <(awk -F'|' '$1 == 4 {print $2}' "$NORMALIZED_ALLOWLIST")
mapfile -t IPV6_SOURCES < <(awk -F'|' '$1 == 6 {print $2}' "$NORMALIZED_ALLOWLIST")
(( ${#IPV4_SOURCES[@]} + ${#IPV6_SOURCES[@]} > 0 )) || die "白名单为空。"

# 始终保护标准端口 22；sshd -T 还能覆盖 Include 后配置的其他有效端口。
SSH_PORTS=(22)
if command -v sshd >/dev/null 2>&1; then
  mapfile -t DETECTED_SSH_PORTS < <(sshd -T 2>/dev/null | awk '$1 == "port" && $2 ~ /^[0-9]+$/ {print $2}' | sort -nu)
  SSH_PORTS+=("${DETECTED_SSH_PORTS[@]}")
fi

# 当前连接的服务端端口也必须纳入保护，兼容非 22 端口 SSH。
CURRENT_SSH_SOURCE=""
CURRENT_SSH_PORT=""
if [[ -n ${SSH_CONNECTION:-} ]]; then
  read -r CURRENT_SSH_SOURCE _ _ CURRENT_SSH_PORT <<<"$SSH_CONNECTION"
elif [[ -n ${SSH_CLIENT:-} ]]; then
  read -r CURRENT_SSH_SOURCE _ CURRENT_SSH_PORT <<<"$SSH_CLIENT"
fi
if [[ "$CURRENT_SSH_PORT" =~ ^[0-9]+$ ]] && (( CURRENT_SSH_PORT >= 1 && CURRENT_SSH_PORT <= 65535 )); then
  SSH_PORTS+=("$CURRENT_SSH_PORT")
fi

mapfile -t PROTECTED_PORTS < <(printf '%s\n' "${SSH_PORTS[@]}" 5901 5902 | awk '$1 >= 1 && $1 <= 65535' | sort -nu)

# 远程执行时，当前 SSH 源必须已被白名单覆盖，否则拒绝执行以防失联。
if [[ -n "$CURRENT_SSH_SOURCE" ]]; then
  if ! python3 - "$CURRENT_SSH_SOURCE" "$NORMALIZED_ALLOWLIST" <<'PY'
import ipaddress
import pathlib
import sys

client = ipaddress.ip_address(sys.argv[1])
allowed = []
for row in pathlib.Path(sys.argv[2]).read_text().splitlines():
    _, value = row.split("|", 1)
    allowed.append(ipaddress.ip_network(value, strict=False))
raise SystemExit(0 if any(client in network for network in allowed) else 1)
PY
  then
    die "当前 SSH 来源 $CURRENT_SSH_SOURCE 不在白名单中；未修改任何防火墙规则。请先把该 IP 加入文件。"
  fi
fi

if ! command -v nft >/dev/null 2>&1; then
  info "正在安装 nftables……"
  export DEBIAN_FRONTEND=noninteractive
  apt-get update
  apt-get install -y nftables
fi
NFT_BIN="$(command -v nft)"

timestamp="$(date +%Y%m%d-%H%M%S)"
install -d -m 0700 "$BACKUP_ROOT"
BACKUP_DIR="$(mktemp -d "${BACKUP_ROOT}/${timestamp}.XXXXXX")"

backup_path() {
  local target="$1"
  local saved="${BACKUP_DIR}/files${target}"
  local absent="${BACKUP_DIR}/absent${target}"
  if [[ -e "$target" || -L "$target" ]]; then
    install -d -m 0700 "$(dirname "$saved")"
    cp -a -- "$target" "$saved"
  else
    install -d -m 0700 "$(dirname "$absent")"
    : >"$absent"
  fi
}

backup_path "$ALLOWLIST_FILE"
backup_path "$NFT_RULE_FILE"
backup_path "$SERVICE_FILE"
backup_path /etc/ufw/user.rules
backup_path /etc/ufw/user6.rules
"$NFT_BIN" list ruleset >"${BACKUP_DIR}/ruleset-before.txt" 2>/dev/null || true
if "$NFT_BIN" list table inet "$TABLE_NAME" >"${BACKUP_DIR}/table-before.nft" 2>/dev/null; then
  : >"${BACKUP_DIR}/table-existed"
fi
systemctl is-enabled --quiet "$SERVICE_NAME" 2>/dev/null && : >"${BACKUP_DIR}/service-was-enabled" || true
systemctl is-active --quiet "$SERVICE_NAME" 2>/dev/null && : >"${BACKUP_DIR}/service-was-active" || true

# 生成随备份保存的一键回滚脚本。
cat >"${BACKUP_DIR}/rollback.sh" <<ROLLBACK
#!/usr/bin/env bash
set -Eeuo pipefail
[[ \${EUID} -eq 0 ]] || { echo '请使用 sudo 运行回滚脚本。' >&2; exit 1; }
BACKUP_DIR='$BACKUP_DIR'
TABLE_NAME='$TABLE_NAME'
SERVICE_NAME='$SERVICE_NAME'
NFT_BIN='$NFT_BIN'
restore_path() {
  local target="\$1"
  local saved="\${BACKUP_DIR}/files\${target}"
  local absent="\${BACKUP_DIR}/absent\${target}"
  if [[ -e "\$saved" || -L "\$saved" ]]; then
    install -d "\$(dirname "\$target")"
    cp -a -- "\$saved" "\$target"
  elif [[ -e "\$absent" ]]; then
    rm -f -- "\$target"
  fi
}
systemctl disable --now "\$SERVICE_NAME" >/dev/null 2>&1 || true
"\$NFT_BIN" delete table inet "\$TABLE_NAME" >/dev/null 2>&1 || true
restore_path '$ALLOWLIST_FILE'
restore_path '$NFT_RULE_FILE'
restore_path '$SERVICE_FILE'
restore_path /etc/ufw/user.rules
restore_path /etc/ufw/user6.rules
systemctl daemon-reload
if [[ -e "\${BACKUP_DIR}/service-was-enabled" ]]; then
  systemctl enable "\$SERVICE_NAME"
fi
if [[ -e "\${BACKUP_DIR}/service-was-active" ]]; then
  systemctl restart "\$SERVICE_NAME"
elif [[ -e "\${BACKUP_DIR}/table-existed" ]]; then
  "\$NFT_BIN" -f "\${BACKUP_DIR}/table-before.nft"
fi
if [[ -r /etc/ufw/ufw.conf ]] && grep -Eq '^[[:space:]]*ENABLED=yes' /etc/ufw/ufw.conf; then
  ufw reload >/dev/null
fi
echo "已回滚到安装前状态：\$BACKUP_DIR"
ROLLBACK
chmod 0700 "${BACKUP_DIR}/rollback.sh"

ROLLBACK_ARMED=1
rollback_on_error() {
  local status=$?
  trap - ERR
  if [[ ${ROLLBACK_ARMED:-0} -eq 1 ]]; then
    printf '应用失败，正在自动回滚……\n' >&2
    bash "${BACKUP_DIR}/rollback.sh" >&2 || printf '自动回滚未完全成功，请手动运行：sudo bash %s/rollback.sh\n' "$BACKUP_DIR" >&2
  fi
  exit "$status"
}
trap rollback_on_error ERR

install -d -m 0755 "$CONFIG_DIR" "$NFT_DIR"
{
  printf '# 已生效名单。修改后请用“sudo bash 安装脚本 %s”重新运行。\n' "$ALLOWLIST_FILE"
  cut -d'|' -f2 "$NORMALIZED_ALLOWLIST"
} >"$ALLOWLIST_FILE"
chmod 0600 "$ALLOWLIST_FILE"

join_by_comma() {
  local IFS=', '
  printf '%s' "$*"
}

{
  printf '#!/usr/sbin/nft -f\n'
  printf '# Generated by %s on %s\n' "$PROGRAM_NAME" "$(date --iso-8601=seconds)"
  printf 'table inet %s {\n' "$TABLE_NAME"
  printf '  set protected_tcp_ports {\n'
  printf '    type inet_service\n'
  printf '    elements = { %s }\n' "$(join_by_comma "${PROTECTED_PORTS[@]}")"
  printf '  }\n'
  printf '  set allowed_ipv4 {\n'
  printf '    type ipv4_addr\n'
  printf '    flags interval\n'
  if (( ${#IPV4_SOURCES[@]} > 0 )); then
    printf '    elements = { %s }\n' "$(join_by_comma "${IPV4_SOURCES[@]}")"
  fi
  printf '  }\n'
  printf '  set allowed_ipv6 {\n'
  printf '    type ipv6_addr\n'
  printf '    flags interval\n'
  if (( ${#IPV6_SOURCES[@]} > 0 )); then
    printf '    elements = { %s }\n' "$(join_by_comma "${IPV6_SOURCES[@]}")"
  fi
  printf '  }\n'
  printf '  chain input {\n'
  printf '    type filter hook input priority -10; policy accept;\n'
  printf '    iifname "lo" tcp dport @protected_tcp_ports counter return\n'
  printf '    ip saddr @allowed_ipv4 tcp dport @protected_tcp_ports counter return\n'
  printf '    ip6 saddr @allowed_ipv6 tcp dport @protected_tcp_ports counter return\n'
  printf '    tcp dport @protected_tcp_ports counter drop\n'
  printf '  }\n'
  printf '}\n'
} >"$NFT_RULE_FILE"
chmod 0644 "$NFT_RULE_FILE"

# 用临时表名做语法检查，避免与已经存在的正式表冲突。
CHECK_RULE_FILE="${TEMP_DIR}/check.nft"
sed "s/${TABLE_NAME}/${TABLE_NAME}_check_$$/g" "$NFT_RULE_FILE" >"$CHECK_RULE_FILE"
"$NFT_BIN" -c -f "$CHECK_RULE_FILE"

cat >"$SERVICE_FILE" <<UNIT
[Unit]
Description=Restrict SSH and VNC to an IP allowlist
Documentation=file:$ALLOWLIST_FILE
DefaultDependencies=no
Wants=network-pre.target
After=local-fs.target nftables.service
Before=network-pre.target shutdown.target ufw.service ssh.service
Conflicts=shutdown.target

[Service]
Type=oneshot
ExecStartPre=-$NFT_BIN delete table inet $TABLE_NAME
ExecStart=$NFT_BIN -f $NFT_RULE_FILE
ExecStop=-$NFT_BIN delete table inet $TABLE_NAME
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
UNIT
chmod 0644 "$SERVICE_FILE"

# 如果 UFW 已启用，把白名单规则插到其前部，避免 UFW 再次拦截合法来源。
# 未启用 UFW 时不会启用或重置它，也不会改变其他端口策略。
UFW_ACTIVE=0
if command -v ufw >/dev/null 2>&1 && [[ -r /etc/ufw/ufw.conf ]] && grep -Eq '^[[:space:]]*ENABLED=yes' /etc/ufw/ufw.conf; then
  UFW_ACTIVE=1
  info "检测到 UFW 已启用，正在同步白名单放行规则……"
  ALL_SOURCES=("${IPV4_SOURCES[@]}" "${IPV6_SOURCES[@]}")
  for source in "${ALL_SOURCES[@]}"; do
    for port in "${PROTECTED_PORTS[@]}"; do
      # 清理本脚本前次运行形成的同义规则，保证重复执行不会不断累积。
      for _ in {1..20}; do
        ufw --force delete allow proto tcp from "$source" to any port "$port" >/dev/null 2>&1 || break
      done
      ufw insert 1 allow proto tcp from "$source" to any port "$port" comment "$UFW_COMMENT" >/dev/null
    done
  done
fi

systemctl daemon-reload
systemctl enable "$SERVICE_NAME" >/dev/null
systemctl restart "$SERVICE_NAME"

systemctl is-active --quiet "$SERVICE_NAME"
"$NFT_BIN" list table inet "$TABLE_NAME" >/dev/null

ROLLBACK_ARMED=0
trap - ERR

info "配置完成。"
printf '白名单：IPv4 %d 项，IPv6 %d 项\n' "${#IPV4_SOURCES[@]}" "${#IPV6_SOURCES[@]}"
printf '受保护 TCP 端口：%s\n' "$(join_by_comma "${PROTECTED_PORTS[@]}")"
printf '规则状态：systemctl status %s --no-pager\n' "$SERVICE_NAME"
printf '规则查看：sudo nft list table inet %s\n' "$TABLE_NAME"
printf '一键回滚：sudo bash %s/rollback.sh\n' "$BACKUP_DIR"
if (( UFW_ACTIVE == 1 )); then
  printf 'UFW：已保留原策略并同步合法来源放行规则。\n'
else
  printf 'UFW：未启用；脚本只限制上述端口，不影响其他端口。\n'
fi
