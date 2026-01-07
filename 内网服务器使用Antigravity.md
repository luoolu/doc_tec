下面是一份可直接发给同事/存到 Wiki 的 **Markdown 文档**（复制粘贴即可）。内容按“现象→原因→最终稳定方案（redsocks+iptables 透明代理）→常见问题→一键脚本”组织，适合长期复用。

---

# Antigravity（Linux）在受限网络/代理环境下稳定登录与使用（redsocks + iptables 方案）

## 背景与现象

在 Ubuntu（如 22.04）上运行 Antigravity 时，常见现象包括：

* 启动日志出现：

  * `No OAuth token available`（未登录/Token 未获取）
  * `fetch failed` / `ConnectTimeoutError ... 142.250.*:443`（Google 相关请求超时）
* 即使加了 `--proxy-server=`，仍会出现 **Node 主进程直连**导致超时（Chromium 走了代理，但 Node/undici 没走）。
* 尝试 `proxychains` 时可能出现：

  * zygote/sandbox 冲突导致崩溃（`zygote_host_impl_linux.cc ... Invalid argument`）
  * 或无法启动默认浏览器（`Failed to execute default Web Browser`）

## 根因简述（给同事理解用）

Antigravity 属于打包的 Electron 应用：

* `--proxy-server` 主要影响 **Chromium 网络栈**
* 但部分关键请求由 **Node(undici/fetch)** 发起
* 打包应用通常限制 `NODE_OPTIONS=--require` 这类注入方式，导致无法“在进程内修补 undici 代理”
* 因此需要“进程外”强制接管 TCP 连接：**透明代理（iptables 重定向 + redsocks）**

---

## 最终稳定方案（推荐）：redsocks + iptables（仅劫持当前用户 80/443）

> 前提：本机已有代理端口 `127.0.0.1:17897`（你的环境已验证同时支持 HTTP CONNECT 与 SOCKS5）。

### 0) 快速确认代理端口可用（任选一个验证即可）

```bash
# HTTP CONNECT 代理验证
curl -I -m 10 -x http://127.0.0.1:17897 https://accounts.google.com

# SOCKS5 代理验证
curl -I -m 10 --socks5-hostname 127.0.0.1:17897 https://accounts.google.com
```

---

### 1) 安装并配置 redsocks（建议用 SOCKS5，更稳）

```bash
sudo apt-get update
sudo apt-get install -y redsocks
```

写入配置（把 17897 作为上游 SOCKS5 代理；redsocks 本地监听 12345）：

```bash
sudo tee /etc/redsocks.conf >/dev/null <<'EOF'
base {
  log_debug = off;
  log_info = on;
  daemon = on;
  redirector = iptables;
}
redsocks {
  local_ip = 127.0.0.1;
  local_port = 12345;
  ip = 127.0.0.1;
  port = 17897;
  type = socks5;
}
EOF

sudo systemctl restart redsocks
sudo systemctl enable redsocks
```

可选确认：

```bash
ss -lntp | grep -E ':12345\b' || true
systemctl status redsocks --no-pager | head -n 20
```

---

### 2) iptables：只劫持“当前用户”的 TCP 80/443 到 redsocks（不影响系统服务/其他用户）

```bash
sudo iptables -t nat -N AG_REDIR 2>/dev/null || true
sudo iptables -t nat -F AG_REDIR

# 不劫持本地/内网（按需增删你的企业网段）
sudo iptables -t nat -A AG_REDIR -d 127.0.0.0/8 -j RETURN
sudo iptables -t nat -A AG_REDIR -d 10.0.0.0/8 -j RETURN
sudo iptables -t nat -A AG_REDIR -d 172.16.0.0/12 -j RETURN
sudo iptables -t nat -A AG_REDIR -d 192.168.0.0/16 -j RETURN

# 把 80/443 重定向到 redsocks 本地端口
sudo iptables -t nat -A AG_REDIR -p tcp --dport 80  -j REDIRECT --to-ports 12345
sudo iptables -t nat -A AG_REDIR -p tcp --dport 443 -j REDIRECT --to-ports 12345

# 仅对当前用户 uid 生效
sudo iptables -t nat -A OUTPUT -m owner --uid-owner "$(id -u)" -p tcp -j AG_REDIR
```

验证“透明代理已生效”（此时 curl 不需要再写 `-x`）：

```bash
curl -I -m 10 https://accounts.google.com
```

---

### 3) 启动 Antigravity（建议指定干净 profile，并禁 GPU 以减少渲染问题）

```bash
pkill -u "$USER" -KILL -f 'antigravity|Antigravity|ptyHost|crashpad' || true

/usr/share/antigravity/antigravity \
  --user-data-dir="$HOME/.cache/antigravity-clean-profile" \
  --disable-gpu
```

> 你实际验证：执行 1/2/3 后授权通过即可使用。

---

## 常见问题与处理

### A) 再次弹出 “Another instance is running …”

你已经遇到过：第三步可能仍弹出“第二个实例”，**关闭弹窗后第一个实例可正常使用**。

建议长期做法是：启动前统一清理残留进程 + 单实例锁。

**1) 清理残留进程：**

```bash
pkill -u "$USER" -KILL -f 'antigravity|Antigravity|ptyHost|crashpad' || true
```

**2) 清理单实例锁（只删 Antigravity 相关 lock/Singleton）：**

```bash
for d in \
  "$HOME/.config/Antigravity" "$HOME/.config/antigravity" \
  "$HOME/.local/share/Antigravity" "$HOME/.local/share/antigravity" \
  "$HOME/.cache/Antigravity" "$HOME/.cache/antigravity"
do
  [[ -d "$d" ]] || continue
  find "$d" -maxdepth 2 \( -name 'Singleton*' -o -name '*.lock' \) -print -delete 2>/dev/null || true
  find "$d" -maxdepth 2 -type s -name 'Singleton*' -print -delete 2>/dev/null || true
done
```

---

### B) `net::ERR_EMPTY_RESPONSE`（自动更新检查失败）

这种通常不影响核心使用（可能是更新域名被策略丢包、代理对特定域不稳定等）。
若功能正常可忽略；若影响使用再针对该域做单独排查（比如代理规则/证书/拦截）。

---

### C) 不想长期劫持：如何一键回滚透明代理

随时执行以下命令即可撤销 **当前用户的** iptables 劫持：

```bash
sudo iptables -t nat -D OUTPUT -m owner --uid-owner "$(id -u)" -p tcp -j AG_REDIR 2>/dev/null || true
sudo iptables -t nat -F AG_REDIR 2>/dev/null || true
sudo iptables -t nat -X AG_REDIR 2>/dev/null || true
```

> 提醒：iptables 规则通常 **重启不会自动保留**（除非你额外做了持久化），所以多数情况下无需担心“永久影响系统”。

---

## 一键脚本（推荐：放到 ~/bin 方便同事复制）

### 1) 开启透明代理：`~/bin/ag-proxy-on`

```bash
cat > ~/bin/ag-proxy-on <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

UPSTREAM_HOST="127.0.0.1"
UPSTREAM_PORT="17897"
REDSOCKS_PORT="12345"

sudo apt-get update -y
sudo apt-get install -y redsocks

sudo tee /etc/redsocks.conf >/dev/null <<CONF
base {
  log_debug = off;
  log_info = on;
  daemon = on;
  redirector = iptables;
}
redsocks {
  local_ip = 127.0.0.1;
  local_port = ${REDSOCKS_PORT};
  ip = ${UPSTREAM_HOST};
  port = ${UPSTREAM_PORT};
  type = socks5;
}
CONF

sudo systemctl restart redsocks
sudo systemctl enable redsocks

sudo iptables -t nat -N AG_REDIR 2>/dev/null || true
sudo iptables -t nat -F AG_REDIR

sudo iptables -t nat -A AG_REDIR -d 127.0.0.0/8 -j RETURN
sudo iptables -t nat -A AG_REDIR -d 10.0.0.0/8 -j RETURN
sudo iptables -t nat -A AG_REDIR -d 172.16.0.0/12 -j RETURN
sudo iptables -t nat -A AG_REDIR -d 192.168.0.0/16 -j RETURN

sudo iptables -t nat -A AG_REDIR -p tcp --dport 80  -j REDIRECT --to-ports ${REDSOCKS_PORT}
sudo iptables -t nat -A AG_REDIR -p tcp --dport 443 -j REDIRECT --to-ports ${REDSOCKS_PORT}

sudo iptables -t nat -A OUTPUT -m owner --uid-owner "$(id -u)" -p tcp -j AG_REDIR

echo "[OK] Transparent proxy enabled for uid=$(id -u). redsocks:${REDSOCKS_PORT} -> socks5 ${UPSTREAM_HOST}:${UPSTREAM_PORT}"
EOF

chmod +x ~/bin/ag-proxy-on
```

### 2) 关闭透明代理：`~/bin/ag-proxy-off`

```bash
cat > ~/bin/ag-proxy-off <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

sudo iptables -t nat -D OUTPUT -m owner --uid-owner "$(id -u)" -p tcp -j AG_REDIR 2>/dev/null || true
sudo iptables -t nat -F AG_REDIR 2>/dev/null || true
sudo iptables -t nat -X AG_REDIR 2>/dev/null || true

echo "[OK] Transparent proxy disabled for uid=$(id -u)."
EOF

chmod +x ~/bin/ag-proxy-off
```

### 3) 启动 Antigravity：`~/bin/ag-run`

```bash
cat > ~/bin/ag-run <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

PROFILE_DIR="${HOME}/.cache/antigravity-clean-profile"

pkill -u "$USER" -KILL -f 'antigravity|Antigravity|ptyHost|crashpad' 2>/dev/null || true

# 清理单实例锁（可选，但能减少“第二个实例”弹窗）
for d in \
  "$HOME/.config/Antigravity" "$HOME/.config/antigravity" \
  "$HOME/.local/share/Antigravity" "$HOME/.local/share/antigravity" \
  "$HOME/.cache/Antigravity" "$HOME/.cache/antigravity"
do
  [[ -d "$d" ]] || continue
  find "$d" -maxdepth 2 \( -name 'Singleton*' -o -name '*.lock' \) -delete 2>/dev/null || true
  find "$d" -maxdepth 2 -type s -name 'Singleton*' -delete 2>/dev/null || true
done

exec /usr/share/antigravity/antigravity \
  --user-data-dir="$PROFILE_DIR" \
  --disable-gpu
EOF

chmod +x ~/bin/ag-run
```

### 使用顺序（同事照抄即可）

```bash
~/bin/ag-proxy-on
~/bin/ag-run
# 用完想恢复：
~/bin/ag-proxy-off
```

---

如果你希望我再给你一个“公司内分享版”（把敏感信息如端口/路径抽成变量、加上注释/FAQ、并补上截图位置说明），我也可以直接帮你再出一份更“讲人话”的版本。

****************************************************************** usage  ******************************************************

不需要每次都手动 `pkill + 手敲启动命令` 才能用。现在你这套“透明代理（redsocks+iptables）”已经把 **Node/undici 直连**的问题解决了，剩下主要是把 **启动/关闭**做得更顺手、尽量“点一下/一条命令”。

下面给你 3 个更友好的用法（从最省事到最“像产品”）。

---

## 方案 A：一条命令启动，退出后自动恢复网络（推荐）

思路：写一个 `ag` 脚本：

1. 开启透明代理（需要 sudo）
2. 启动 Antigravity
3. 你关闭 Antigravity 后，脚本自动执行“关闭透明代理”（trap）

### 1) 增强版 `ag-proxy-on`（避免重复加规则）

把你之前的 `ag-proxy-on` 改成“先检查是否已存在”：

```bash
cat > ~/bin/ag-proxy-on <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

UPSTREAM_HOST="127.0.0.1"
UPSTREAM_PORT="17897"
REDSOCKS_PORT="12345"
UID_NOW="$(id -u)"

sudo apt-get update -y >/dev/null
sudo apt-get install -y redsocks >/dev/null

sudo tee /etc/redsocks.conf >/dev/null <<CONF
base {
  log_debug = off;
  log_info = on;
  daemon = on;
  redirector = iptables;
}
redsocks {
  local_ip = 127.0.0.1;
  local_port = ${REDSOCKS_PORT};
  ip = ${UPSTREAM_HOST};
  port = ${UPSTREAM_PORT};
  type = socks5;
}
CONF

sudo systemctl restart redsocks >/dev/null

sudo iptables -t nat -N AG_REDIR 2>/dev/null || true
sudo iptables -t nat -F AG_REDIR

sudo iptables -t nat -A AG_REDIR -d 127.0.0.0/8 -j RETURN
sudo iptables -t nat -A AG_REDIR -d 10.0.0.0/8 -j RETURN
sudo iptables -t nat -A AG_REDIR -d 172.16.0.0/12 -j RETURN
sudo iptables -t nat -A AG_REDIR -d 192.168.0.0/16 -j RETURN

sudo iptables -t nat -A AG_REDIR -p tcp --dport 80  -j REDIRECT --to-ports ${REDSOCKS_PORT}
sudo iptables -t nat -A AG_REDIR -p tcp --dport 443 -j REDIRECT --to-ports ${REDSOCKS_PORT}

# OUTPUT 规则如果已存在就不重复加
if ! sudo iptables -t nat -C OUTPUT -m owner --uid-owner "${UID_NOW}" -p tcp -j AG_REDIR 2>/dev/null; then
  sudo iptables -t nat -A OUTPUT -m owner --uid-owner "${UID_NOW}" -p tcp -j AG_REDIR
fi

echo "[OK] Transparent proxy ON (uid=${UID_NOW}) redsocks:${REDSOCKS_PORT} -> socks5 ${UPSTREAM_HOST}:${UPSTREAM_PORT}"
EOF

chmod +x ~/bin/ag-proxy-on
```

### 2) `ag-proxy-off`（不变也行，我给一个更稳的）

```bash
cat > ~/bin/ag-proxy-off <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
UID_NOW="$(id -u)"

sudo iptables -t nat -D OUTPUT -m owner --uid-owner "${UID_NOW}" -p tcp -j AG_REDIR 2>/dev/null || true
sudo iptables -t nat -F AG_REDIR 2>/dev/null || true
sudo iptables -t nat -X AG_REDIR 2>/dev/null || true

echo "[OK] Transparent proxy OFF (uid=${UID_NOW})"
EOF

chmod +x ~/bin/ag-proxy-off
```

### 3) 一条命令启动并自动回滚：`~/bin/ag`

```bash
cat > ~/bin/ag <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

PROFILE_DIR="${HOME}/.cache/antigravity-clean-profile"

cleanup() {
  # 退出 Antigravity 后自动关闭透明代理
  ~/bin/ag-proxy-off >/dev/null 2>&1 || true
}
trap cleanup EXIT

# 开透明代理（需要 sudo；第一次会让你输密码）
~/bin/ag-proxy-on

# 不要每次都 KILL，先温柔关（没有也不会报错）
pkill -u "$USER" -TERM -f 'antigravity|Antigravity|ptyHost|crashpad' 2>/dev/null || true
sleep 0.5

exec /usr/share/antigravity/antigravity \
  --user-data-dir="$PROFILE_DIR" \
  --disable-gpu
EOF

chmod +x ~/bin/ag
```

以后你就只需要：

```bash
~/bin/ag
```

关闭方式：**正常点窗口关闭/退出**即可；你退出后网络会自动恢复（iptables 规则被清掉）。

---

## 方案 B：更“无感”的方式：开机/登录后常驻透明代理（不自动关闭）

如果你希望 **之后随时直接点 Antigravity 图标就能用**，可以只在登录后跑一次：

```bash
~/bin/ag-proxy-on
```

以后直接启动：

```bash
/usr/share/antigravity/antigravity --disable-gpu
```

不用时手动关：

```bash
~/bin/ag-proxy-off
```

> 这更像“环境准备一次，应用随便开”。

---

## 方案 C：关闭/重启更友好：提供一个 `ag-stop`

有时候 Antigravity 会残留 ptyHost / crashpad，导致“第二个实例”弹窗。给你一个一键关闭脚本：

```bash
cat > ~/bin/ag-stop <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

# 先 TERM 再 KILL
pkill -u "$USER" -TERM -f 'antigravity|Antigravity|ptyHost|crashpad' 2>/dev/null || true
sleep 1
pkill -u "$USER" -KILL -f 'antigravity|Antigravity|ptyHost|crashpad' 2>/dev/null || true

# 清理单实例锁（可选但很有效）
for d in \
  "$HOME/.config/Antigravity" "$HOME/.config/antigravity" \
  "$HOME/.local/share/Antigravity" "$HOME/.local/share/antigravity" \
  "$HOME/.cache/Antigravity" "$HOME/.cache/antigravity" \
  "$HOME/.cache/antigravity-clean-profile"
do
  [[ -d "$d" ]] || continue
  find "$d" -maxdepth 2 \( -name 'Singleton*' -o -name '*.lock' \) -delete 2>/dev/null || true
  find "$d" -maxdepth 2 -type s -name 'Singleton*' -delete 2>/dev/null || true
done

echo "[OK] Antigravity stopped and locks cleaned."
EOF

chmod +x ~/bin/ag-stop
```

以后卡住/弹“第二个实例”，就：

```bash
~/bin/ag-stop
~/bin/ag
```

---

## 你日志里的几个点顺便解释一下

* `No OAuth token available`：启动时先报一次很常见，只要后面能正常进入就不用管。
* `ptyHost terminated unexpectedly with code 0`：多见于它的终端子进程组件退出，一般不影响主功能。
* “第二个实例”偶发：多数是 lock 残留或上次退出不干净，用 `ag-stop` + 清 lock 能明显减少。

---

如果你希望再“丝滑”一点（比如 **不用每次输 sudo 密码**），我也可以给你一份最小化的 `sudoers` 配置（只放行 `redsocks` 重启和特定 iptables 命令，风险可控），这样同事直接 `~/bin/ag` 就一键全通。

