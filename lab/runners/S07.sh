#!/usr/bin/env bash
# S07 — Credential access: LSASS read on Erebor, via Atomic Red Team.
# Requires Invoke-AtomicTest (Atomic Red Team) installed on Erebor and OpenSSH.
# No credentials leave the lab; this exercises Sysmon Event 10 telemetry only.
# See scenarios/S07-lsass-cred-access.md.
run_scenario() {
  # T1003.001 has several test numbers; pick one by VARIANT. Adjust to the
  # test numbers present in your Atomics if these drift.
  local TEST; case "$VARIANT" in 1) TEST=1;; 2) TEST=2;; *) TEST=3;; esac

  step "run Atomic T1003.001 test $TEST on Erebor (LSASS access)"
  on_win "atomic-run" "powershell -c \"Import-Module Invoke-AtomicRedTeam; Invoke-AtomicTest T1003.001 -TestNumbers $TEST -GetPrereqs; Invoke-AtomicTest T1003.001 -TestNumbers $TEST\""
  note "Invoke-AtomicTest T1003.001 -TestNumbers $TEST"

  step "cleanup the Atomic test artifacts"
  on_win "atomic-cleanup" "powershell -c \"Import-Module Invoke-AtomicRedTeam; Invoke-AtomicTest T1003.001 -TestNumbers $TEST -Cleanup\""
  note "atomic cleanup done; revert Erebor to baseline afterward"

  noise_win
}
