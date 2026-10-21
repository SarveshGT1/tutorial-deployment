# Git Bash from zero

Never opened a terminal? Start here. This page takes you from a laptop without Git Bash to the first screen of the
workshop wizard in about 15 minutes. Do it before the workshop if you can.

A terminal is a window where you type commands instead of clicking. Git Bash is the terminal that comes with Git
for Windows. It runs Bash, the same command language Macs and Linux servers use, which is why one script can walk
everybody through the workshop the same way. The wizard only copies one file, opens web pages and checks numbers.
It doesn't change anything else on your laptop.

## 1. Check whether Git Bash is already installed

1. Press the **Windows key** and type `Git Bash`.
2. If **Git Bash** shows up in the results, it's installed. Skip to section 3.
3. If nothing shows up, go to section 2.

## 2. Install Git for Windows

Git Bash is part of Git for Windows. On a GT laptop you install it from the Software Center, which doesn't need
admin rights.

1. Press the **Windows key**, type `Software Center` (Softwarecentrum) and open it.
2. Search for `Git`.
3. Click **Git for Windows**, then **Install** (Installeren). It takes a few minutes.
4. Can't find it in the Software Center? Ask the facilitator before the workshop, not during it.

Not in the Software Center? On GT laptops `winget`, Windows' own installer, works too. Open **PowerShell** (Windows key,
type `PowerShell`, Enter) and run:
```
winget install --id Git.Git -e
```
Then open Git Bash from the Start menu.

On a laptop where you're allowed to install software yourself, you can also download the installer from
`https://git-scm.com/download/win`. Click **Next** on every screen: the default choices are right for this
workshop. Two of them matter, so leave them as they are:

- **Git Bash Here** stays ticked. It adds "Open Git Bash here" to the right-click menu.
- **Use MinTTY** stays selected. MinTTY is the window Git Bash runs in, with colours and proper copy and paste.

**Check it worked.** Open Git Bash (Windows key, type `Git Bash`, Enter) and type:
```
git --version
```
Press Enter. You should see a line like `git version 2.47.1.windows.1`. The exact number doesn't matter.

## 3. Get the workshop files

The facilitator shares `tutorial-deployment.zip` in the workshop Teams channel.

1. Download the zip. It lands in your **Downloads** folder.
2. Right-click the zip and choose **Extract All** (Alles uitpakken), then **Extract** (Uitpakken).
3. A folder called `tutorial-deployment` opens. Inside it are `start.cmd`, `start.sh`, and the folders `data`,
   `guide` and `steps`.

Don't double-click your way into the zip and run things from there. Windows only shows you a preview of the
files, and the wizard can't find its data.

Have access to the GitHub repo? Then you can clone it instead of downloading the zip. Open Git Bash and type:
```
cd ~/Downloads
git clone https://github.com/SarveshGT1/tutorial-deployment.git
```

## 4. Open Git Bash in the workshop folder

Git Bash works in one folder at a time, so it has to start in `tutorial-deployment`. There are three ways to do
that. Use the first one that works.

**Way 1: double-click `start.cmd`.** It finds Git Bash, opens a window at the right size in the right folder, and
starts the wizard. If Windows shows "Windows protected your PC", click **More info**, then **Run anyway**.

**Way 2: right-click the folder.** In File Explorer, right-click the `tutorial-deployment` folder. On Windows 11,
choose **Show more options** first. Then choose **Open Git Bash here**.

**Way 3: open Git Bash and walk to the folder.** Open Git Bash from the Start menu and type:
```
cd ~/Downloads/tutorial-deployment
```

**Check you're in the right place.** Type `ls` and press Enter. You should see these names, maybe in a different
order:
```
data  GIT-BASH.md  guide  README.md  start.cmd  start.sh  steps  tools  TROUBLESHOOTING.md
```
If you see something else, type `pwd` to see where you are, and use way 3 to get to the folder.

## 5. Git Bash in five minutes

These are all the commands you need today, and a few that will save you when something looks odd.

| type this | and it |
|---|---|
| `pwd` | shows which folder you're in ("print working directory") |
| `ls` | lists what's in the folder |
| `cd data` | goes into the folder `data` |
| `cd ..` | goes up one folder |
| `cd ~` | goes to your user folder, like `C:\Users\you` |
| `clear` | wipes the screen |
| `bash start.sh` | runs the workshop wizard |

**Tab finishes words for you.** Type `cd tut` and press **Tab**: Git Bash completes it to `cd tutorial-deployment/`.
Use it everywhere; it saves typos.

**The up arrow brings back your last command.** Press it again to go further back. Handy when you want to run the
wizard again.

**Copy and paste work differently from Word.** In Git Bash:
- Copy: select text with the mouse. With the default settings that already copies it. **Ctrl+Insert** also works.
- Paste: **Shift+Insert**, or right-click and choose **Paste**.
- **Ctrl+C does not copy.** It stops whatever is running. In the wizard that's fine: your progress is saved.
- **Ctrl+V does not paste** in a default Git Bash window. Use Shift+Insert.

**Windows paths look different.** Git Bash writes `C:\Users\you\Downloads` as `/c/Users/you/Downloads`, with
forward slashes. `~` is short for your user folder, so `~/Downloads` is your Downloads folder. A folder name with
spaces needs quotes: `cd "OneDrive - Company name"`.

**Text too small?** **Ctrl+plus** makes it bigger, **Ctrl+minus** smaller, **Ctrl+0** resets it.
**Window too small?** Drag the bottom-right corner, or press **Alt+Enter** for full screen (Alt+Enter again to go
back).

**Lost?** Close the window and open it again with way 2 from section 4. Nothing breaks when you close Git Bash.

## 6. Check your laptop with the doctor

Before the wizard, let it check the laptop:
```
bash start.sh doctor
```
Each line starts with ✓ (fine) or ! (look at this). Under every ! is the fix. Two results are common and harmless:

- **OneDrive not found:** you'll upload the Excel file by hand in step 2. The wizard shows you how.
- **Window smaller than 100 x 34:** drag the window bigger.

Everything else with a ! is worth fixing first. [TROUBLESHOOTING.md](TROUBLESHOOTING.md) has the details, or ask
the facilitator.

## 7. Run the wizard

```
bash start.sh
```

Type your first name when it asks, and follow the screens. Every step has four screens:

| key | screen |
|---|---|
| Enter | step done, on to the next one |
| w | why this step matters (+10 XP the first time) |
| i | what happens inside (+10 XP the first time) |
| h | stuck? the fixes for this step |
| g | open the visual guide in your browser |
| b | back one step |
| q | quit; your progress is saved |

Type the letter and press **Enter**. Most steps end with a quiz (type a, b or c), and three steps ask you for a
number that the script checks against the Excel file.

**Put the windows side by side.** Click Git Bash and press **Windows key + left arrow**. Click your browser and press
**Windows key + right arrow**. Now you can read the wizard while you click in the browser.

**Stopping and continuing.** Press q, or just close the window. Next time, open Git Bash in the same folder and type
`bash start.sh` again: you continue at the same step, with the same XP.

Useful extras:
```
bash start.sh --step 8    # jump to step 8; your XP stays
bash start.sh --ascii     # plain characters, if you see boxes or question marks
bash start.sh --reset     # start over from zero
bash start.sh --help      # this list
```

## 8. Bonus: the Copilot Studio CLI

After step 15 the wizard offers a bonus round with the Copilot Studio CLI, `pac copilot`. It's part of the Power
Platform CLI, and it's how GT ships agents: written as YAML files, kept in Git, deployed from a laptop. In three
steps you install it, find your own agent from Git Bash, and clone that agent into a folder of text files. The
wizard runs every command for you and shows it first, so you see exactly what was typed.

Want to try the commands yourself afterwards? These are the ones the bonus round uses:
```
winget install Microsoft.PowerAppsCLI      # once, then open a NEW Git Bash window
pac auth create                            # sign in; a browser window opens
pac org who                                # which environment am I in?
pac env list                               # all environments, with their URLs
pac copilot list                           # the agents in this environment
pac copilot clone --bot <id> --output-dir agent-code
```

Two things that trip people up:
- **pac isn't found right after installing.** Close every Git Bash window and open a new one. Programs you
  install only show up in new windows.
- **Your agent isn't in `pac copilot list`.** You're signed in to another environment. Run `pac env list`, copy
  the workshop environment's URL, and run `pac auth create --environment <that URL>`.

## 9. After the workshop

- Your agent and flows stay in the workshop environment. Delete them there if the facilitator asks you to.
- `bash start.sh --reset` wipes your progress on the laptop. Deleting the `tutorial-deployment` folder removes
  everything else, including the cloned `agent-code` folder.
- The copy of `koffie.xlsx` in your OneDrive folder `GT-Agent-Workshop` is yours to keep or delete.
