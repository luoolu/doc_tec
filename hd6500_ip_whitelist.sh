#!/bin/sh
# HD6500 / DSM 7.x inbound IP allowlist
#
# Examples:
#   sudo sh hd6500_ip_whitelist.sh apply 10.20.1.15 10.20.2.0/24
#   sudo sh hd6500_ip_whitelist.sh apply --file /volume1/scripts/hd6500_allowlist.txt
#   sudo sh hd6500_ip_whitelist.sh audit --file /volume1/scripts/hd6500_allowlist.txt
#   sudo sh hd6500_ip_whitelist.sh confirm
#
# The manual "apply" action starts a safety watchdog. If "confirm" is not run
# within ROLLBACK_SECONDS, all rules created by this script are removed.

set -u

ROLLBACK_SECONDS="${ROLLBACK_SECONDS:-300}"
AUTO_ALLOW_SSH_CLIENT="${AUTO_ALLOW_SSH_CLIENT:-1}"

CHAIN4_A="H6500WL4A"
CHAIN4_B="H6500WL4B"
CHAIN6_A="H6500WL6A"
CHAIN6_B="H6500WL6B"
PENDING_FILE="/tmp/hd6500-ip-whitelist.pending"
WATCHDOG_LOG="/tmp/hd6500-ip-whitelist-watchdog.log"
LOCK_DIR="/tmp/hd6500-ip-whitelist.lock"
TMP4="/tmp/hd6500-ip-whitelist-v4.$$"
TMP6="/tmp/hd6500-ip-whitelist-v6.$$"

SCRIPT_DIR=$(CDPATH= cd "$(dirname "$0")" 2>/dev/null && pwd)
SELF="$SCRIPT_DIR/$(basename "$0")"

say()  { printf '%s\n' "$*"; }
warn() { printf 'WARNING: %s\n' "$*" >&2; }
die()  { printf 'ERROR: %s\n' "$*" >&2; exit 1; }

cleanup_tmp() {
    rm -f "$TMP4" "$TMP6"
}

release_lock() {
    rmdir "$LOCK_DIR" 2>/dev/null || true
}

trap 'cleanup_tmp; release_lock' EXIT HUP INT TERM

usage() {
    cat <<'EOF'
HD6500 / DSM 7.x inbound IP allowlist

Usage:
  sudo sh hd6500_ip_whitelist.sh apply IP_OR_CIDR...
  sudo sh hd6500_ip_whitelist.sh apply --file ALLOWLIST_FILE
  sudo sh hd6500_ip_whitelist.sh boot  --file ALLOWLIST_FILE
  sudo sh hd6500_ip_whitelist.sh audit --file ALLOWLIST_FILE
  sudo sh hd6500_ip_whitelist.sh status
  sudo sh hd6500_ip_whitelist.sh confirm
  sudo sh hd6500_ip_whitelist.sh disable

Actions:
  apply    Validate and enable the allowlist. Auto-rollback after 300 seconds
           unless "confirm" is run. The current SSH client IP is automatically
           added for this application by default.
  boot     Re-apply without an auto-rollback timer. Intended only for a DSM
           Task Scheduler boot-up/scheduled task after a successful test.
  audit    Verify that the supplied list is present and enforced at INPUT #1.
  status   Display active chains, rules, and packet counters.
  confirm  Cancel the pending safety rollback after successful testing.
  disable  Remove only the rules/chains created by this script.

Allowlist file format:
  One IPv4/IPv6 address or CIDR per line. Blank lines and # comments are ignored.
  Hostname and start-end IP ranges are intentionally not accepted.

Example:
  10.122.161.210
  10.122.162.0/24       # office subnet
  2001:db8:1234::10/128

Environment overrides:
  ROLLBACK_SECONDS=600 AUTO_ALLOW_SSH_CLIENT=0 sudo -E sh ...
EOF
}

need_root() {
    [ "$(id -u)" = "0" ] || die "Run this action as root (use sudo)."
}

find_cmd() {
    _name="$1"
    _found=$(command -v "$_name" 2>/dev/null || true)
    if [ -z "$_found" ]; then
        for _path in "/sbin/$_name" "/usr/sbin/$_name" "/usr/local/sbin/$_name"; do
            if [ -x "$_path" ]; then
                _found="$_path"
                break
            fi
        done
    fi
    [ -n "$_found" ] || return 1
    printf '%s\n' "$_found"
}

acquire_lock() {
    _wait=0
    while ! mkdir "$LOCK_DIR" 2>/dev/null; do
        _wait=$((_wait + 1))
        [ "$_wait" -le 15 ] || die "Another whitelist operation is still running."
        sleep 1
    done
}

normalize_line() {
    # Remove CR, comments, and surrounding whitespace.
    printf '%s\n' "$1" | tr -d '\r' | sed 's/#.*$//;s/^[[:space:]]*//;s/[[:space:]]*$//'
}

append_source() {
    _src="$1"
    [ -n "$_src" ] || return 0
    case "$_src" in
        *[[:space:]]*) die "Invalid entry containing whitespace: $_src" ;;
    esac
    case "$_src" in
        *:*) printf '%s\n' "$_src" >> "$TMP6" ;;
        *)   printf '%s\n' "$_src" >> "$TMP4" ;;
    esac
}

load_sources() {
    : > "$TMP4"
    : > "$TMP6"

    [ "$#" -gt 0 ] || die "No allowlist supplied. Use IP/CIDR arguments or --file FILE."
    if [ "$1" = "--file" ]; then
        [ "$#" -eq 2 ] || die "Use exactly: --file ALLOWLIST_FILE"
        _file="$2"
        [ -r "$_file" ] || die "Cannot read allowlist file: $_file"
        while IFS= read -r _raw || [ -n "$_raw" ]; do
            _line=$(normalize_line "$_raw")
            append_source "$_line"
        done < "$_file"
    else
        for _raw in "$@"; do
            _line=$(normalize_line "$_raw")
            append_source "$_line"
        done
    fi

    if [ "$action" = "apply" ] && [ "$AUTO_ALLOW_SSH_CLIENT" = "1" ] && [ -n "${SSH_CLIENT:-}" ]; then
        _ssh_ip=${SSH_CLIENT%% *}
        if [ -n "$_ssh_ip" ]; then
            case "$_ssh_ip" in
                *:*) _ssh_file="$TMP6" ;;
                *)   _ssh_file="$TMP4" ;;
            esac
            if ! grep -qxF "$_ssh_ip" "$_ssh_file" 2>/dev/null; then
                printf '%s\n' "$_ssh_ip" >> "$_ssh_file"
                warn "Current SSH client $_ssh_ip was added to this application for safety."
                warn "If it is not covered by a listed CIDR, add it to the persistent allowlist before creating the boot task."
            fi
        fi
    fi

    _total=$(( $(wc -l < "$TMP4") + $(wc -l < "$TMP6") ))
    [ "$_total" -gt 0 ] || die "The normalized allowlist is empty."
}

chain_exists() {
    "$1" -t filter -nL "$2" >/dev/null 2>&1
}

jump_exists() {
    "$1" -t filter -C INPUT -j "$2" >/dev/null 2>&1
}

remove_jumps() {
    _bin="$1"
    _chain="$2"
    while jump_exists "$_bin" "$_chain"; do
        "$_bin" -t filter -D INPUT -j "$_chain" >/dev/null 2>&1 || break
    done
}

delete_chain() {
    _bin="$1"
    _chain="$2"
    remove_jumps "$_bin" "$_chain"
    if chain_exists "$_bin" "$_chain"; then
        "$_bin" -t filter -F "$_chain" >/dev/null 2>&1 || return 1
        "$_bin" -t filter -X "$_chain" >/dev/null 2>&1 || return 1
    fi
    return 0
}

choose_new_chain() {
    _bin="$1"
    _a="$2"
    _b="$3"
    if jump_exists "$_bin" "$_a"; then
        printf '%s\n' "$_b"
    else
        printf '%s\n' "$_a"
    fi
}

build_chain() {
    _bin="$1"
    _chain="$2"
    _family="$3"
    _sources="$4"

    delete_chain "$_bin" "$_chain" || die "Cannot remove stale chain $_chain."
    "$_bin" -t filter -N "$_chain" || die "Cannot create chain $_chain."

    _ok=1
    "$_bin" -t filter -A "$_chain" -i lo -j ACCEPT || _ok=0
    "$_bin" -t filter -A "$_chain" -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT || _ok=0

    if [ "$_family" = "4" ]; then
        # Preserve DHCP renewal if the NAS interface is DHCP-configured.
        "$_bin" -t filter -A "$_chain" -p udp --sport 67 --dport 68 -j ACCEPT || _ok=0
    else
        # DHCPv6 plus ICMPv6 control/error traffic required for correct IPv6 operation.
        "$_bin" -t filter -A "$_chain" -p udp --sport 547 --dport 546 -j ACCEPT || _ok=0
        for _icmp6 in 1 2 3 4 133 134 135 136 137; do
            "$_bin" -t filter -A "$_chain" -p ipv6-icmp --icmpv6-type "$_icmp6" -j ACCEPT || _ok=0
        done
    fi

    while IFS= read -r _src || [ -n "$_src" ]; do
        [ -n "$_src" ] || continue
        if ! "$_bin" -t filter -A "$_chain" -s "$_src" -j ACCEPT; then
            warn "Rejected invalid IPv$_family address/CIDR: $_src"
            _ok=0
            break
        fi
    done < "$_sources"

    "$_bin" -t filter -A "$_chain" -j DROP || _ok=0

    if [ "$_ok" != "1" ]; then
        delete_chain "$_bin" "$_chain" || true
        die "Could not build IPv$_family rules. Existing active rules were not replaced."
    fi
}

activate_chain() {
    _bin="$1"
    _new="$2"
    _a="$3"
    _b="$4"

    # Insert the complete new chain first; traffic remains protected throughout the swap.
    "$_bin" -t filter -I INPUT 1 -j "$_new" || die "Cannot attach chain $_new to INPUT."

    for _old in "$_a" "$_b"; do
        [ "$_old" = "$_new" ] && continue
        remove_jumps "$_bin" "$_old"
        if chain_exists "$_bin" "$_old"; then
            "$_bin" -t filter -F "$_old" >/dev/null 2>&1 || true
            "$_bin" -t filter -X "$_old" >/dev/null 2>&1 || true
        fi
    done
}

first_input_rule() {
    # DSM 7.x with iptables-legacy may expose the requested INPUT chain as
    # DEFAULT_INPUT in both -S and -L output. Match the first appended rule
    # instead of assuming that the printed chain name is literally INPUT.
    "$1" -t filter -S INPUT 2>/dev/null | awk '$1 == "-A" { print; exit }'
}

audit_family() {
    _bin="$1"
    _a="$2"
    _b="$3"
    _sources="$4"
    _family="$5"
    _active=""
    _count=0

    for _chain in "$_a" "$_b"; do
        if jump_exists "$_bin" "$_chain"; then
            _active="$_chain"
            _count=$((_count + 1))
        fi
    done
    [ "$_count" -eq 1 ] || {
        warn "IPv$_family FAIL: expected one active chain, found $_count."
        return 1
    }

    _first=$(first_input_rule "$_bin")
    case "$_first" in
        *"-j $_active"*) ;;
        *) warn "IPv$_family FAIL: $_active is not the first INPUT rule."; return 1 ;;
    esac

    while IFS= read -r _src || [ -n "$_src" ]; do
        [ -n "$_src" ] || continue
        if ! "$_bin" -t filter -C "$_active" -s "$_src" -j ACCEPT >/dev/null 2>&1; then
            warn "IPv$_family FAIL: missing allow rule for $_src."
            return 1
        fi
    done < "$_sources"

    _last=$("$_bin" -t filter -S "$_active" 2>/dev/null | awk '$1 == "-A" { last=$0 } END { print last }')
    case "$_last" in
        *"-j DROP") ;;
        *) warn "IPv$_family FAIL: terminal DROP rule is missing."; return 1 ;;
    esac

    say "IPv$_family PASS: $_active is INPUT rule #1 and ends with DROP."
    return 0
}

show_family() {
    _bin="$1"
    _a="$2"
    _b="$3"
    _family="$4"
    _found=0

    for _chain in "$_a" "$_b"; do
        if jump_exists "$_bin" "$_chain"; then
            _found=1
            say "IPv$_family active chain: $_chain"
            "$_bin" -t filter -nvxL "$_chain" --line-numbers
        fi
    done
    [ "$_found" = "1" ] || say "IPv$_family: not active"
}

disable_all() {
    _ipt="$1"
    _ip6t="$2"
    for _chain in "$CHAIN4_A" "$CHAIN4_B"; do
        delete_chain "$_ipt" "$_chain" || warn "Could not fully delete $_chain."
    done
    if [ -n "$_ip6t" ]; then
        for _chain in "$CHAIN6_A" "$CHAIN6_B"; do
            delete_chain "$_ip6t" "$_chain" || warn "Could not fully delete $_chain."
        done
    fi
    rm -f "$PENDING_FILE"
    say "Whitelist rules created by this script are disabled."
}

start_watchdog() {
    _token="$(date +%s).$$"
    printf '%s\n' "$_token" > "$PENDING_FILE"
    nohup /bin/sh "$SELF" _watchdog "$_token" "$ROLLBACK_SECONDS" >"$WATCHDOG_LOG" 2>&1 &
    say "Safety rollback armed for $ROLLBACK_SECONDS seconds."
    say "After testing from an allowed host, run: sudo sh $SELF confirm"
}

action="${1:-help}"
[ "$#" -gt 0 ] && shift || true

case "$action" in
    help|-h|--help)
        usage
        exit 0
        ;;
    apply|boot|audit|status|confirm|disable|_watchdog)
        ;;
    *)
        usage >&2
        die "Unknown action: $action"
        ;;
esac

need_root
IPT=$(find_cmd iptables) || die "iptables was not found."
IP6T=$(find_cmd ip6tables || true)

if [ "$action" = "_watchdog" ]; then
    [ "$#" -eq 2 ] || exit 1
    _token="$1"
    _seconds="$2"
    sleep "$_seconds"
    if [ -r "$PENDING_FILE" ] && [ "$(cat "$PENDING_FILE")" = "$_token" ]; then
        acquire_lock
        warn "Whitelist was not confirmed; automatic rollback is running."
        disable_all "$IPT" "$IP6T"
    fi
    exit 0
fi

acquire_lock

case "$action" in
    apply|boot)
        load_sources "$@"
        _new4=$(choose_new_chain "$IPT" "$CHAIN4_A" "$CHAIN4_B")

        if [ -n "$IP6T" ] && "$IP6T" -t filter -nL INPUT >/dev/null 2>&1; then
            _use_ip6=1
            _new6=$(choose_new_chain "$IP6T" "$CHAIN6_A" "$CHAIN6_B")
        else
            _use_ip6=0
            _new6=""
            if [ -s /proc/net/if_inet6 ]; then
                die "IPv6 is active but ip6tables is unavailable; refusing a partial whitelist."
            fi
        fi

        # Build both families completely before either is attached.
        build_chain "$IPT" "$_new4" 4 "$TMP4"
        if [ "$_use_ip6" = "1" ]; then
            build_chain "$IP6T" "$_new6" 6 "$TMP6"
        fi

        # Arm rollback before changing live rules, so a post-activation error is also recoverable.
        if [ "$action" = "apply" ]; then
            start_watchdog
        fi

        activate_chain "$IPT" "$_new4" "$CHAIN4_A" "$CHAIN4_B"
        if [ "$_use_ip6" = "1" ]; then
            activate_chain "$IP6T" "$_new6" "$CHAIN6_A" "$CHAIN6_B"
        fi

        say "Inbound allowlist applied: $(wc -l < "$TMP4") IPv4 and $(wc -l < "$TMP6") IPv6 entries."
        audit_family "$IPT" "$CHAIN4_A" "$CHAIN4_B" "$TMP4" 4 || die "IPv4 post-apply audit failed."
        if [ "$_use_ip6" = "1" ]; then
            audit_family "$IP6T" "$CHAIN6_A" "$CHAIN6_B" "$TMP6" 6 || die "IPv6 post-apply audit failed."
        fi

        if [ "$action" = "boot" ]; then
            rm -f "$PENDING_FILE"
            say "Boot/scheduled mode: no rollback watchdog was started."
        fi
        ;;
    audit)
        load_sources "$@"
        _rc=0
        audit_family "$IPT" "$CHAIN4_A" "$CHAIN4_B" "$TMP4" 4 || _rc=1
        if [ -n "$IP6T" ] && "$IP6T" -t filter -nL INPUT >/dev/null 2>&1; then
            audit_family "$IP6T" "$CHAIN6_A" "$CHAIN6_B" "$TMP6" 6 || _rc=1
        elif [ -s /proc/net/if_inet6 ]; then
            warn "IPv6 FAIL: IPv6 is active but ip6tables is unavailable."
            _rc=1
        fi
        [ "$_rc" = "0" ] || exit 1
        say "AUDIT PASS: supplied allowlist is enforced."
        ;;
    status)
        show_family "$IPT" "$CHAIN4_A" "$CHAIN4_B" 4
        if [ -n "$IP6T" ] && "$IP6T" -t filter -nL INPUT >/dev/null 2>&1; then
            show_family "$IP6T" "$CHAIN6_A" "$CHAIN6_B" 6
        fi
        if [ -r "$PENDING_FILE" ]; then
            warn "A safety rollback is still pending; run confirm after external testing."
        fi
        ;;
    confirm)
        if [ -e "$PENDING_FILE" ]; then
            rm -f "$PENDING_FILE"
            say "Confirmed. The pending automatic rollback was cancelled."
        else
            say "No pending rollback was found."
        fi
        ;;
    disable)
        disable_all "$IPT" "$IP6T"
        ;;
esac

exit 0
