#!/usr/bin/env bash
# dealer.sh — deal a case, fire it against the range, seal the ground truth.
#
# NOTE: This is the standalone prototype Draghunt grew out of. In normal use,
# lay exercises in Draghunt, which dispatches the same runners in lab/runners/
# and seals the answer key on its own side. Keep dealer.sh for manual runs and
# for previewing a plan with --dry-run when Draghunt isn't handy.
#
# Runs FROM Barad-dûr (the Kali attacker, 192.168.45.75). It:
#   1. picks a scenario (random, or --scenario Sxx),
#   2. randomizes the parameters (source IP, account, variant, success, noise,
#      jitter),
#   3. seals the ground truth to lab/.groundtruth/ (git-ignored) so morning-you
#      investigates blind,
#   4. calls the matching runner in lab/runners/ to actually execute the attack
#      against the victims, appending the real commands and timestamps to the
#      sealed file as it goes.
#
# The range is NOT assumed to exist. Until it does, use --dry-run to print the
# full plan without touching a box. Once the range is up, drop --dry-run.
#
# Usage:
#   ./lab/dealer.sh                    # random scenario, fire it, sealed
#   ./lab/dealer.sh --scenario S05     # specific scenario
#   ./lab/dealer.sh --scenario S05 --dry-run   # print the plan, touch nothing
#   ./lab/dealer.sh --seal-only        # randomize + seal, don't fire (fire by hand)
#   ./lab/dealer.sh --list             # show the deck
set -euo pipefail
cd "$(dirname "$0")/.."

# ---- config ------------------------------------------------------------------
[[ -f lab/lab.env ]] && source lab/lab.env
SEAL="${SEAL_DIR:-lab/.groundtruth}"; mkdir -p "$SEAL"

SCENARIOS=(S01 S02 S03 S04 S05 S06 S07 S08 S09 S10)
declare -A NAME=(
  [S01]="SSH brute force to successful login"
  [S02]="Linux privilege escalation"
  [S03]="Web shell upload on DVWA"
  [S04]="Persistence: cron/systemd"
  [S05]="Malicious PowerShell cradle"
  [S06]="LOLBin download"
  [S07]="LSASS credential access"
  [S08]="Lateral movement"
  [S09]="DNS exfiltration"
  [S10]="Prompt-injection exfil"
)

# ---- args --------------------------------------------------------------------
SCN=""; DRY_RUN=0; SEAL_ONLY=0
while [[ $# -gt 0 ]]; do
  case "$1" in
    --list)      for s in "${SCENARIOS[@]}"; do printf '%s  %s\n' "$s" "${NAME[$s]}"; done; exit 0 ;;
    --scenario)  SCN="${2:-}"; shift 2 ;;
    --dry-run)   DRY_RUN=1; shift ;;
    --seal-only) SEAL_ONLY=1; shift ;;
    -h|--help)   sed -n '2,26p' "$0"; exit 0 ;;
    *)           echo "unknown arg: $1" >&2; exit 2 ;;
  esac
done
export DRY_RUN

[[ -z "$SCN" ]] && SCN="${SCENARIOS[$RANDOM % ${#SCENARIOS[@]}]}"
if [[ -z "${NAME[$SCN]:-}" ]]; then echo "no such scenario: $SCN" >&2; exit 2; fi

# ---- randomized parameters ---------------------------------------------------
octet=$(( (RANDOM % 200) + 20 ))
SRC_IP="${ATTACKER_IP:-10.10.10.5}"          # attacks originate from Barad-dûr
SUCCEED=$([[ $((RANDOM % 2)) == 1 ]] && echo yes || echo no)
NOISE=$([[ $((RANDOM % 2)) == 1 ]] && echo yes || echo no)
DELAY=$(( (RANDOM % 55) + 5 ))               # minutes of jitter before firing
USERS=(svc-backup jsmith admin deploy monitor); ACCOUNT="${USERS[$RANDOM % ${#USERS[@]}]}"
VARIANT=$(( (RANDOM % 3) + 1 ))              # A/B/C sub-variant, meaning is per-scenario

STAMP="$(date -u +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || echo UNKNOWN)"
SEALFILE="$SEAL/$(date -u +%Y%m%d-%H%M 2>/dev/null || echo run)-$SCN.txt"

cat > "$SEALFILE" <<SEALED
# SEALED GROUND TRUTH — do not open until your verdict is written
scenario:   $SCN — ${NAME[$SCN]}
staged_utc: $STAMP
source_ip:  $SRC_IP
account:    $ACCOUNT
variant:    $VARIANT
succeed:    $SUCCEED
noise:      $NOISE
jitter_min: $DELAY
mode:       $([[ $DRY_RUN == 1 ]] && echo dry-run || { [[ $SEAL_ONLY == 1 ]] && echo seal-only || echo live; })
# --- what actually ran (appended by the runner) ---
SEALED
chmod 600 "$SEALFILE"

echo "Dealt: $SCN — ${NAME[$SCN]}"
echo "Ground truth sealed → $SEALFILE (do not open it)"
echo "  source IP : $SRC_IP"
echo "  account   : $ACCOUNT"
echo "  variant   : $VARIANT"
echo "  succeed   : $SUCCEED"
echo "  noise     : $NOISE"

# ---- fire --------------------------------------------------------------------
export SCN SRC_IP ACCOUNT VARIANT SUCCEED NOISE DELAY SEALFILE

if [[ $SEAL_ONLY == 1 ]]; then
  echo
  echo "Seal-only: not firing. Run scenarios/$SCN-*.md by hand with the params above,"
  echo "then append the exact commands and timestamps to $SEALFILE."
  exit 0
fi

RUNNER="lab/runners/$SCN.sh"
if [[ ! -f "$RUNNER" ]]; then
  echo "No runner at $RUNNER — falling back to seal-only." >&2
  exit 0
fi

if [[ "$DELAY" -gt 0 && "$DRY_RUN" == "0" ]]; then
  echo
  echo "Jitter: sleeping ${DELAY} min before firing (so the clock isn't a tell)."
  echo "  Ctrl-C to fire now; the seal is already written."
  sleep "$((DELAY * 60))" || true
fi

echo
echo "Firing $SCN via $RUNNER $([[ $DRY_RUN == 1 ]] && echo '(dry run)')"
# shellcheck disable=SC1090
source lab/runners/_lib.sh
source "$RUNNER"
run_scenario

echo
echo "Done. Investigate from Wazuh in the morning, write cases/$(date -u +%F 2>/dev/null || echo YYYY-MM-DD).md,"
echo "then grade against $SEALFILE."
