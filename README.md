# tutorial-deployment · build a barista

This is the hands-on part of the GT builders workshop. Each participant goes from an empty folder to a working Copilot Studio
agent that answers "Hoeveel cappuccino's zijn er besteld?" from an Excel file in their OneDrive. A Git Bash wizard
walks them through 15 steps, one screen at a time, with XP, levels, badges, quizzes and three number checks.
About 45 minutes. A bonus round of three steps (about 10 minutes) then puts the agent in files with the Copilot
Studio CLI, `pac copilot`: the way GT ships agents.

## For participants

Never used Git Bash? [GIT-BASH.md](GIT-BASH.md) covers everything from installing it to running the wizard, in
about 15 minutes. The same text is the "Git Bash from zero" section of the guide.

1. Unzip the folder (right-click, **Extract All**).
2. Double-click **`start.cmd`**. Or right-click the folder, **Open Git Bash here**, and type `bash start.sh`.
3. Follow the screens. Open `guide/index.html` in your browser for the same steps with diagrams.

Keys on every screen:

| key | does |
|---|---|
| Enter | step done, next |
| w | why this step matters (+10 XP the first time) |
| i | what happens inside (+10 XP the first time) |
| h | stuck? fixes for this step |
| g | open the visual guide |
| b | back one step |
| q | quit; progress is saved, run it again to continue |

Something odd? `bash start.sh doctor` checks the laptop and prints the fix next to each problem.
All fixes are also in [TROUBLESHOOTING.md](TROUBLESHOOTING.md).

## The 15 steps

Each step has four screens in the wizard and four blocks in the guide: **Do** (the clicks), **Why** (why it
matters), **Inside** (what happens under the hood) and **Stuck?** (fixes). Twelve steps end with a quiz; steps 7,
13 and 15 end with a number that code checks against the file.

| act | step | what you do |
|---|---|---|
| 1 · The data | 1 | Check in; your name names your agent |
| | 2 | The script makes `GT-Agent-Workshop` in OneDrive and copies `koffie.xlsx` into it |
| | 3 | Find the table `Bestellingen` in Excel for the web |
| 2 · The flow | 4 | Power Automate: instant cloud flow, trigger **Handmatig een stroom activeren** |
| | 5 | Add the text input `drankje` |
| | 6 | Excel Online (Business): list rows, Filterquery `Drankje eq '[drankje]'` |
| | 7 | Test twice; the script checks the row count (8) |
| 3 · The agent | 8 | Classic experience: new agent "Barista <name>"; the instructions go on the clipboard |
| | 9 | Generative orchestration on, web search and general knowledge off |
| | 10 | New agent flow, trigger **Wanneer een agent de stroom aanroept**, input `drankje` |
| | 11 | Same Excel step, **Reageren op de agent** with `aantal` = `length(value)`; publish as "Koffie tellen" |
| | 12 | Tool description and **Dynamisch invullen met AI**; publish the agent |
| | 13 | Ask the agent; the script checks its answer (8) |
| | 14 | Add a cappuccino row in Excel; the agent changes its answer without being touched |
| | 15 | The script checks the new answer (9) |
| Bonus · the agent as code | 16 | Install the Copilot Studio CLI (`winget install Microsoft.PowerAppsCLI`) |
| | 17 | `pac auth create`, then `pac copilot list`; the script finds "Barista <name>" |
| | 18 | `pac copilot clone` into `agent-code/`; the script finds the instructions in the YAML |

**Why two flows.** An agent can only call a flow that starts with **Wanneer een agent de stroom aanroept**. The
Handmatig flow in act 2 is for testing by hand; act 3 builds the same logic behind the agent trigger.

## XP, levels and badges

| earn | XP |
|---|---|
| finish a step | +100 |
| open a step's Why or Inside screen | +10 each |
| quiz right first time / second time | +50 / +20 |
| quiz streak | +10 per quiz in a row, max +50 |
| checks at steps 7 and 13 / step 15 | +100 / +250 (half after a wrong try) |
| bonus: agent found with pac (17), agent cloned (18) | +150 each |
| every badge | +50 |

Levels: Trainee 0 · Assistant 400 · Senior 1000 · Manager 1600 · Director 2300 · Partner 3000. A perfect run
scores 3700 after step 15 and 4610 with the bonus round. Badges: Data drop, Deterministic, Agent born, Live data,
Quiz master, Curious, Speedrun (within 40 minutes), Partner, and Agent as code from the bonus round. The final screen puts a one-line score on the clipboard to post in the workshop chat.

## Windows details

- `start.cmd` finds Git for Windows in Program Files or the per-user install, opens it in mintty at 100 × 34,
  and runs `bash -o igncr`, so Windows line endings can't break the script.
- Every keyboard read strips `\r`. `.gitattributes` keeps `.sh` and step files LF, and `start.cmd` CRLF.
- The clipboard goes through PowerShell `Set-Clipboard` (keeps é and quotes), then `clip.exe` with UTF-16.
- OneDrive is found through `%OneDriveCommercial%`, then `%OneDrive%`, then a `OneDrive - *` folder. An existing
  `koffie.xlsx` is never overwritten, so re-running step 2 can't wipe a participant's new row.
- Unicode looks wrong? `bash start.sh --ascii` gives the same wizard in plain characters.

## For facilitators

**The day before**
- [ ] Put the zip in the workshop Teams channel.
- [ ] Everyone can create flows and agents in the workshop environment.
- [ ] The DLP policy allows Excel Online (Business) in that environment.
- [ ] One dry run on a GT laptop, steps 1 to 18, with `bash start.sh doctor` first.
- [ ] Write the workshop environment's URL on the board (`pac env list` shows it). Step 17 asks for it.

**Check in the GT tenant (about 10 minutes; none of this is verified yet)**
- [ ] `https://gtnl-my.sharepoint.com` lands on your own OneDrive (steps 2 and 3).
- [ ] The Dutch label for **Open classic experience** in Copilot Studio (step 8).
- [ ] The labels **Nieuwe agentwerkstroom**, **Reageren op de agent**, **Dynamisch invullen met AI** (steps 10 to 12).
- [ ] `OneDriveCommercial` is set in Git Bash on a GT laptop: `echo "$OneDriveCommercial"`.
- [ ] mintty accepts the window size from `start.cmd`, and SmartScreen's reaction to `start.cmd` from a zip.

Fix a label in `steps/NN.txt`, then run `python3 tools/build-guide.py` so the guide matches.

## Repo layout

```
GIT-BASH.md            the full Git Bash tutorial for participants, from install to first screen
start.cmd              double-click launcher (Windows)
start.sh               the wizard: screens, XP, quizzes, checks, doctor
steps/01.txt … 18.txt  the step texts: Do, Why, Inside, quiz, Stuck? (16 to 18 are the pac bonus round)
guide/index.html       the visual guide, built from steps/ and TROUBLESHOOTING.md
guide/img/             GT logo, Microsoft icons, three Microsoft Learn screenshots
data/koffie.xlsx       30 synthetic orders in table Bestellingen (Nr, Naam, Afdeling, Drankje, Suiker)
data/instructies.txt   the agent instructions (Dutch)
tools/build-guide.py   steps/ → guide/index.html
tools/test-wizard.sh   plays all 18 steps with CRLF input and a stand-in pac, and checks the ending
```

## Answer key (code calculates)

cappuccino 8 · latte 6 · espresso 5 · thee 4 · chocomel 3 · flat white 4 = 30 orders. After step 14: cappuccino 9.
