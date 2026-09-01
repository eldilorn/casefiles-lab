# YYYY-MM-DD — [title]

*A short, specific title. Say what the case is about, not what the answer is. Example: "Encoded PowerShell on a Windows host overnight".*

## The question

*What was genuinely unresolved when I sat down. One or two sentences. Did the brute force succeed? Is this PowerShell admin work or a download cradle? Did anything leave the network? A bare alert is not a question. Turn it into one.*

## Indicator / subject

*The thing that started the case: the Wazuh alert, the host, the account, the process, the connection, the file. Describe it in prose so a reader with no context understands what I was looking at. Lab assets only.*

## What I did (pivots/tools, in order)

*The investigation as it actually happened, step by step, in the order I ran it. Name the tool and the pivot for each step: Wazuh alerts and archives, Sysmon, auditd, raw host logs, pcap, external lookups. Include the dead ends. Two or three careful pivots beat six shallow ones.*

## What I found

*The evidence, stated plainly. Timestamps, hosts, accounts, commands, connections, and what each one tells me. Facts here, interpretation in the next section. If the logs could not answer the question, say exactly what was missing.*

## Verdict & confidence

*The call, in one line, followed by a confidence level (low, medium, high) and why. Did the attack succeed? Benign or malicious? Which host was touched first? "Inconclusive, ran out of time, next pivot would be X" is a complete verdict. If I could not tell from the telemetry alone, that is the finding: name the blind spot.*

## One thing I learned

*A single takeaway. A log source I should have checked first, a rule that was too noisy, a technique that looked different from what I expected. One thing, not a list.*

## Tomorrow's first move

*Where the next session starts. One concrete action: the pivot I did not get to, the rule to write, the scenario to re-run with different parameters. Written so tomorrow-me does not have to decide anything.*

---

## Detection

*Optional. If the case ends in a detection artifact, it goes here: a tuned Wazuh rule, a Sigma rule, or a hunting query, tested against the attack that produced the telemetry. Include the rule as a code block, a sentence on what it fires on, and a sentence on what it would miss or where it might be noisy. A case that ships a working rule is worth three that do not, but most days this section stays empty.*
