#!/usr/bin/env bash
# _lib.sh — shared helpers for the scenario runners.
#
# Runners are invoked by the caller — Draghunt (the product) in normal use, or
# lab/dealer.sh (the standalone prototype) for manual runs — which exports the
# randomized parameters (SCN, SRC_IP, ACCOUNT, VARIANT, SUCCEED, NOISE, DELAY)
# and the config from lab/lab.env. Everything here runs FROM Barad-dûr.
#
# Two ideas keep this honest:
#   * DRY_RUN=1  -> print every command instead of running it. Use this before
#                   the range exists, or any time you want to see the plan.
#   * note()     -> append what actually happened to the sealed ground-truth
#                   file, so grading has the real commands and timestamps.

set -uo pipefail

# ---- output helpers ----------------------------------------------------------
say()  { printf '  %s\n' "$*"; }
step() { printf '\n▶ %s\n' "$*"; }
warn() { printf '  ! %s\n' "$*" >&2; }

# ---- ground-truth ledger -----------------------------------------------------
# SEALFILE is exported by the caller (Draghunt, or dealer.sh in manual runs).
note() {
  [[ -n "${SEALFILE:-}" ]] || return 0
  printf '%s | %s\n' "$(now)" "$*" >> "$SEALFILE"
}
now() { date -u +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || echo UNKNOWN; }

# ---- command execution -------------------------------------------------------
# run <label> <command...>  — run locally on Barad-dûr (or print if DRY_RUN).
run() {
  local label="$1"; shift
  if [[ "${DRY_RUN:-0}" == "1" ]]; then
    printf '  [dry] local: %s\n' "$*"
    note "DRY local  ($label): $*"
    return 0
  fi
  say "local: $*"
  note "local ($label): $*"
  bash -c "$*"
}

# _ssh <ip> <user> <command...> — run a command on a victim over SSH.
_ssh() {
  local ip="$1" user="$2"; shift 2
  # shellcheck disable=SC2086
  ssh -i "$SSH_KEY" $SSH_OPTS "${user}@${ip}" "$@"
}

# on_lin  <label> <command...> — run on Moria as the admin user.
# on_lin_as <user> <label> <command...> — run on Moria as an arbitrary user.
on_lin()     { on_host "$VICLIN_IP"  "$VICLIN_USER"  "moria"  "$@"; }
on_lin2()    { on_host "$VICLIN2_IP" "$VICLIN2_USER" "moria2" "$@"; }
on_win()     { on_host "$VICWIN_IP"  "$VICWIN_USER"  "erebor" "$@"; }
on_lin_as()  { local u="$1"; shift; on_host "$VICLIN_IP" "$u" "moria($u)" "$@"; }

# on_host <ip> <user> <name> <label> <command...>
on_host() {
  local ip="$1" user="$2" name="$3" label="$4"; shift 4
  local cmd="$*"
  if [[ "${DRY_RUN:-0}" == "1" ]]; then
    printf '  [dry] %s@%s (%s): %s\n' "$user" "$name" "$label" "$cmd"
    note "DRY ssh ${user}@${name} ($label): $cmd"
    return 0
  fi
  say "${user}@${name}: $cmd"
  note "ssh ${user}@${name} ($label): $cmd"
  _ssh "$ip" "$user" "$cmd"
}

# ---- attacker staging server -------------------------------------------------
# serve_stage — start a background HTTP server in STAGE_DIR on Barad-dûr so the
# victims can download from http://ATTACKER_IP:STAGE_HTTP_PORT/. Returns after
# recording the PID in STAGE_PID. Call stop_stage when done.
STAGE_PID=""
serve_stage() {
  mkdir -p "$STAGE_DIR"
  if [[ "${DRY_RUN:-0}" == "1" ]]; then
    printf '  [dry] serve %s on :%s\n' "$STAGE_DIR" "$STAGE_HTTP_PORT"
    note "DRY serve $STAGE_DIR on :$STAGE_HTTP_PORT"
    return 0
  fi
  ( cd "$STAGE_DIR" && python3 -m http.server "$STAGE_HTTP_PORT" >/dev/null 2>&1 ) &
  STAGE_PID=$!
  say "staging http://$ATTACKER_IP:$STAGE_HTTP_PORT/ (pid $STAGE_PID)"
  note "staging server up (pid $STAGE_PID) serving $STAGE_DIR"
  sleep 1
}
stop_stage() {
  [[ -n "$STAGE_PID" ]] || return 0
  [[ "${DRY_RUN:-0}" == "1" ]] && return 0
  kill "$STAGE_PID" 2>/dev/null || true
  note "staging server stopped (pid $STAGE_PID)"
  STAGE_PID=""
}

# drop_stage_file <name> <contents> — write a file into STAGE_DIR to be served.
drop_stage_file() {
  local name="$1" body="$2"
  mkdir -p "$STAGE_DIR"
  if [[ "${DRY_RUN:-0}" == "1" ]]; then
    printf '  [dry] stage file %s/%s\n' "$STAGE_DIR" "$name"
    return 0
  fi
  printf '%s' "$body" > "$STAGE_DIR/$name"
  say "staged $STAGE_DIR/$name"
}

# ---- optional benign noise ---------------------------------------------------
# fire_noise runs when NOISE=yes so the case isn't the only thing in the logs.
# Cheap, benign activity on the same box the scenario touched.
noise_lin() {
  [[ "${NOISE:-no}" == "yes" ]] || return 0
  step "benign noise on Moria"
  on_lin_as "$FOOTHOLD_USER" "noise" \
    'for c in "ls -la /tmp" "id" "df -h" "uptime" "cat /etc/os-release"; do eval $c >/dev/null 2>&1; done; true'
}
noise_win() {
  [[ "${NOISE:-no}" == "yes" ]] || return 0
  step "benign noise on Erebor"
  on_win "noise" 'powershell -c "Get-Process | Out-Null; Get-Service | Out-Null; whoami; hostname"'
}

# ---- guards ------------------------------------------------------------------
require_dryrun_or_range() {
  if [[ "${DRY_RUN:-0}" != "1" ]]; then
    warn "About to run LIVE against the range. The range must be built and the"
    warn "SSH key installed on the victims. If it is not, re-run with --dry-run."
  fi
}
