#!/usr/bin/env bash
# dealer.sh — stage a case file blind.
# Picks a scenario (or takes --scenario Sxx), randomizes parameters, and SEALS
# the ground truth to lab/.groundtruth/ so morning-you investigates cold.
#
# This is a STAGER/RANDOMIZER + ledger. It prints the randomized parameters and
# the run commands for the chosen scenario; you (or a wrapper you write per host)
# execute them against the range. It deliberately does not SSH into your victims
# for you — keep the attack step deliberate and lab-local. Fill in run_* hooks
# below if you want it to drive the boxes directly.
#
# Usage:
#   ./lab/dealer.sh                 # random scenario, random params, sealed
#   ./lab/dealer.sh --scenario S05  # specific scenario
#   ./lab/dealer.sh --list          # show the deck
set -euo pipefail
cd "$(dirname "$0")/.."
SEAL="lab/.groundtruth"; mkdir -p "$SEAL"

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

if [[ "${1:-}" == "--list" ]]; then
  for s in "${SCENARIOS[@]}"; do printf '%s  %s\n' "$s" "${NAME[$s]}"; done; exit 0
fi

SCN=""
[[ "${1:-}" == "--scenario" ]] && SCN="${2:-}"
[[ -z "$SCN" ]] && SCN="${SCENARIOS[$RANDOM % ${#SCENARIOS[@]}]}"

# Randomized, sealed parameters. bash $RANDOM is fine for lab variety.
octet=$(( (RANDOM % 200) + 20 ))
SRC_IP="10.10.10.$octet"
SUCCEED=$(( RANDOM % 2 ))                       # did the attack succeed?
NOISE=$(( RANDOM % 2 ))                         # inject benign noise alongside?
DELAY=$(( (RANDOM % 55) + 5 ))                  # minutes of jitter before firing
USERS=(svc-backup jsmith admin deploy monitor); USER="${USERS[$RANDOM % ${#USERS[@]}]}"
VARIANT=$(( (RANDOM % 3) + 1 ))                 # A/B/C style sub-variant (see scenario)

STAMP="$(date -u +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || echo UNKNOWN)"
SEALFILE="$SEAL/$(date -u +%Y%m%d-%H%M 2>/dev/null || echo run)-$SCN.txt"

cat > "$SEALFILE" <<SEALED
# SEALED GROUND TRUTH — do not open until your verdict is written
scenario:   $SCN — ${NAME[$SCN]}
staged_utc: $STAMP
source_ip:  $SRC_IP
account:    $USER
variant:    $VARIANT
succeed:    $([[ $SUCCEED == 1 ]] && echo yes || echo no)
noise:      $([[ $NOISE == 1 ]] && echo yes || echo no)
jitter_min: $DELAY
notes:      (add exact commands you ran + observed timestamps here right after firing)
SEALED
chmod 600 "$SEALFILE"

echo "Dealt: $SCN — ${NAME[$SCN]}"
echo "Ground truth sealed → $SEALFILE (do not open it)"
echo
echo "Run scenarios/$SCN-*.md with these randomized params:"
echo "  source IP : $SRC_IP"
echo "  account   : $USER"
echo "  variant   : $VARIANT"
echo "  succeed   : $([[ $SUCCEED == 1 ]] && echo 'make it work' || echo 'let it fail')"
echo "  noise     : $([[ $NOISE == 1 ]] && echo 'fire benign activity too' || echo 'clean')"
echo "  jitter    : wait ~$DELAY min before firing (so the clock isn't a tell)"
echo
echo "Then, in the morning: investigate from Wazuh, write cases/$(date -u +%F 2>/dev/null || echo YYYY-MM-DD).md, grade against the seal."
