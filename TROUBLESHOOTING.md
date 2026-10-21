# Troubleshooting

Start here: `bash start.sh doctor` checks your laptop and prints what's wrong, with the fix next to it.

## Starting the wizard

### "Open Git Bash here" isn't in the right-click menu
Windows 11 hides it. Right-click the folder, choose **Show more options**, then **Open Git Bash here**.
Still not there? Double-click `start.cmd` in the folder instead. It finds Git Bash for you.

### Git Bash isn't installed
Install **Git for Windows** from the Software Center (Softwarecentrum), then try again. You don't need admin
rights for the Software Center version.

### `$'\r': command not found` or `syntax error near unexpected token`
The script got Windows line endings, usually because it went through an e-mail, Teams or a Git setting that
converts them. Run it like this instead, which ignores them:
```
bash -o igncr start.sh
```
`start.cmd` already does this.

### "Windows protected your PC" when double-clicking start.cmd
SmartScreen blocks files that came from the internet. Click **More info**, then **Run anyway**. Or right-click
`start.cmd`, **Properties**, tick **Unblock**, **OK**.

### "data/koffie.xlsx not found"
You're running it from inside the zip. Right-click the zip, **Extract All** (Alles uitpakken), open the extracted
folder and start again.

### The screen shows boxes, question marks or `â”€`
Your terminal isn't using UTF-8. Run `bash start.sh --ascii` for a plain-text version of the same wizard.

### Lines wrap or the screen doesn't fit
Make the window bigger: about 100 × 34 characters. `start.cmd` opens it at that size.

### I want to start over or jump to a step
```
bash start.sh --reset      # wipes your progress and XP
bash start.sh --step 8     # jump to step 8 (your XP stays)
```

## Act 1 · The data

### The script can't find my OneDrive
It looks for the Windows variable `OneDriveCommercial`, then for a folder called `OneDrive - …` in your user
folder. If OneDrive isn't running or isn't signed in, neither exists. Upload by hand: in the browser open OneDrive,
**+ Nieuw** → **Map** → `GT-Agent-Workshop`, open it, **Uploaden** → **Bestanden** → `data/koffie.xlsx`.

### "Permission denied" or "Device or resource busy" when copying
`koffie.xlsx` is open in desktop Excel. Close it, press **b**, then Enter to try step 2 again.

### The file doesn't show up in the browser
OneDrive syncs within about 30 seconds. A red cross on the OneDrive cloud icon means you're signed out; click it
and sign in. Then refresh the browser (F5).

### There's no "Tabelontwerp" tab
Click a cell inside the data first. The tab only appears when the cursor is in a table.

## Act 2 · The flow

### Wrong environment
Top right in Power Automate and Copilot Studio: **Omgeving** (Environment). Pick the one the facilitator named.
The flow and the agent must be in the same environment.

### The Excel step returns 0 rows
The filter must be exactly `Drankje eq 'cappuccino'`: column name with a capital D, the value in small letters,
straight single quotes. Curly quotes (‘ ’) from Word or Outlook don't work; retype them in the browser.

### "The file is locked" or "resource busy"
Someone has `koffie.xlsx` open in desktop Excel. Close it. Excel for the web is fine.

### "Table not found"
The table must be called `Bestellingen`. Check in Excel for the web: **Tabelontwerp** → **Tabelnaam**.

### There's no Filterquery field
Open **Geavanceerde parameters** (Advanced parameters) or **Alles weergeven** (Show all) under the Excel step.

## Act 3 · The agent

### No "Open classic experience"
On the Copilot Studio home page, use **Other ways to build** / **Andere manieren om te bouwen**, or **+ Maken** →
**Nieuwe agent** → **Configureren**.

### The clipboard is empty when I paste the instructions
Press **b**, then Enter on step 8 to copy them again. Or open `data/instructies.txt` in Notepad, Ctrl+A, Ctrl+C.

### Koffie tellen isn't in the tool list
Publish the agent flow first (step 11). Then **Hulpmiddelen** → **+ Een hulpmiddel toevoegen** → **Werkstroom** →
**Koffie tellen**.

### The agent answers but doesn't use the tool
Check in this order:
- **Instellingen** → **Generatieve AI**: orchestration is **Generatief**
- The tool's description says what it does: "Telt hoeveel bestellingen er zijn voor één drankje."
- The input `drankje` is set to **Dynamisch invullen met AI**
- Start a new test chat (the refresh icon): old chats keep old settings

### I changed the flow but the agent still does the old thing
Publish the flow, then remove the tool from the agent and add it again. The agent keeps the old version until you do.

### Still 8 after adding a row
The new row must be inside the table: it gets the table's colour. If it doesn't, drag the small handle at the
table's bottom-right corner down one row. Then start a new test chat.

## Still stuck

Run `bash start.sh doctor`, take a screenshot of it, and wave at the facilitator.
