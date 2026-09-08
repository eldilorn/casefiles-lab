# Draghunt runner catalog

This directory is Draghunt's **private scenario catalog**: one JSON file per live
scenario, in the same metadata shape as Draghunt's demo deck, plus `"live": true`.
The attacks themselves are dispatched by `../fire.sh` (protocol v1); the scenario
prose stays in `../../scenarios/`.

## Point Draghunt at this range

In the Draghunt dashboard, open **Settings** and set:

- **Private scenario catalog directory** → this folder, e.g. `~/casefiles-lab/lab/catalog`
- Attacker host/user/SSH key → Barad-dûr and the throwaway lab key
- Target host / admin user / Wazuh agent ID → Moria and its agent
- Wazuh indexer URL + read credential

Draghunt's runner defaults (`runner.dir = ~/casefiles-lab/lab`, `runner.entry = fire.sh`)
already match this layout. It invokes `fire.sh` over SSH on the attacker with
`ACTION=preflight|run|cleanup`; `fire.sh` returns one protocol-v1 JSON document.

## Status

- **S01** (SSH brute force) is wired to protocol v1 end to end: preflight is
  read-only, the run reports the *observed* login outcome (from the hydra
  transcript, not the requested success flag), and cleanup removes the seeded
  account. Needs Moria reachable over SSH with a sudo-capable admin, a throwaway
  key installed from Barad-dûr, and `hydra`/`nmap` on the attacker.
- S02–S10 still run through the legacy `dealer.sh` prototype and are not yet
  protocol v1. Add each as `<ID>.json` here and a `run_<ID>`/`pre_<ID>`/`cleanup_<ID>`
  in `fire.sh` as it is converted.

Draghunt only fires scenarios present in this catalog and marked `"live": true`.
