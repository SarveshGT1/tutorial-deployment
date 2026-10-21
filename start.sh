#!/usr/bin/env bash
#
# GT agent workshop: from an empty folder to a working Copilot Studio agent in 15 steps.
#
# Windows: double-click start.cmd, or right-click the folder → Open Git Bash here → bash start.sh
#   bash start.sh doctor     check this laptop, print fixes
#   bash start.sh --ascii    plain characters, for terminals that show boxes or question marks
#   bash start.sh --step 8   jump to a step (XP stays)
#   bash start.sh --reset    start over
#
# The texts live in steps/NN.txt (they also build guide/index.html). This file is the engine: it shows
# the texts, keeps XP and badges, and checks the numbers the flow and the agent give back.

set -uo pipefail

here=$0
command -v cygpath >/dev/null 2>&1 && here=$(cygpath -u "$here")
cd "$(dirname "$here")" || exit 1
[[ -n "${LANG:-}" ]] || export LANG=en_US.UTF-8

TOTAL=15
QUIZZES=12          # steps 7, 13 and 15 have a number check instead of a quiz
FOLDER="GT-Agent-Workshop"
FILE="koffie.xlsx"
PROG=".progress"
TEST=${WORKSHOP_TEST:-0}   # 1 = no browser, no clipboard, no animation (tools/test-wizard.sh)

# Code calculates: the true counts in data/koffie.xlsx (30 orders). Step 14 adds one cappuccino.
expected() { case "$1" in cappuccino) echo 8 ;; latte) echo 6 ;; espresso) echo 5 ;; thee) echo 4 ;; chocomel) echo 3 ;; "flat white") echo 4 ;; esac; }

LEVELS=(0 400 1000 1600 2300 3000)
TITLES=(Trainee Assistant Senior Manager Director Partner)
BADGE_ORDER="DFALQCSP"
badge_name() { case "$1" in D) echo "Data drop" ;; F) echo "Deterministic" ;; A) echo "Agent born" ;; L) echo "Live data" ;;
  Q) echo "Quiz master" ;; C) echo "Curious" ;; S) echo "Speedrun" ;; P) echo "Partner" ;; esac; }
badge_why() { case "$1" in D) echo "your data sits in a named table in the cloud" ;; F) echo "your flow counted, the same way twice" ;;
  A) echo "your agent has a tool it can call" ;; L) echo "the data changed, the agent kept up, code agreed" ;;
  Q) echo "every quiz right the first time" ;; C) echo "read every why and every inside screen" ;;
  S) echo "finished within 40 minutes" ;; P) echo "reached the top of the ladder" ;; esac; }

# ── options ────────────────────────────────────────────────────────────────
ASCII=${GT_ASCII:-0}; MODE=run; JUMP=""
while (($#)); do
  case "$1" in
    doctor|--doctor) MODE=doctor ;;
    --ascii) ASCII=1 ;;
    --reset) MODE=reset ;;
    --step) JUMP=${2:-}; shift ;;
    -h|--help|help) MODE=help ;;
    *) printf 'Unknown option: %s. Try: bash start.sh --help\n' "$1"; exit 2 ;;
  esac
  shift
done

# ── look ───────────────────────────────────────────────────────────────────
if [[ -t 1 && -z "${NO_COLOR:-}" ]]; then
  E=$'\033'; BOLD="$E[1m"; DIM="$E[2m"; RESET="$E[0m"; REV="$E[7m"
  GREEN="$E[32m"; YELLOW="$E[33m"; PURPLE="$E[35m"
  [[ "$(tput colors 2>/dev/null || echo 8)" -ge 256 ]] && PURPLE="$E[38;5;98m"
else
  BOLD=""; DIM=""; RESET=""; REV=""; GREEN=""; YELLOW=""; PURPLE=""
fi
if ((ASCII)); then
  HR="-"; ON="#"; OFF="."; CUR="@"; ARW="->"; OK="+"; STAR="*"; NOSTAR="o"; CUP="c[_]"; FULL="#"; EMPTY="-"; DOT="-"
else
  HR="─"; ON="■"; OFF="□"; CUR="▣"; ARW="→"; OK="✓"; STAR="★"; NOSTAR="☆"; CUP="☕"; FULL="█"; EMPTY="░"; DOT="·"
fi

# --ascii also rewrites the step texts, which use box drawing and a few accents.
asciify() {
  if ((ASCII)); then
    sed -e 's/─/-/g' -e 's/│/|/g' -e 's/└/`/g' -e 's/┐/+/g' -e 's/┘/+/g' -e 's/┼/+/g' -e 's/┤/+/g' -e 's/┌/+/g' \
        -e 's/→/->/g' -e 's/·/-/g' -e 's/é/e/g' -e 's/ë/e/g' -e "s/[‘’]/'/g" -e 's/×/x/g' -e 's/…/.../g' -e 's/☕/c[_]/g'
  else cat; fi
}

cls() { ((TEST)) && { printf '\n=====\n'; return; }; [[ -t 1 ]] && printf '\033[H\033[2J\033[3J'; }
say()  { printf '  %s\n' "$1"; }
good() { printf '  %s%s %s%s\n' "$GREEN" "$OK" "$1" "$RESET"; }
warn() { printf '  %s! %s%s\n' "$YELLOW" "$1" "$RESET"; }
note() { printf '%s\n' "$1" | fold -s -w 68 | sed "s/^/  $DIM/; s/\$/$RESET/"; }
hr()   { local i s=""; for ((i = 0; i < 68; i++)); do s+=$HR; done; printf '  %s%s%s\n' "$DIM" "$s" "$RESET"; }
nap()  { ((TEST)) || sleep "$1"; }

# ask PROMPT: the answer lands in REPLY_, without the \r Windows terminals sometimes send. EOF quits.
ask() {
  printf '  %s%s%s ' "$PURPLE" "$1" "$RESET"
  IFS= read -r REPLY_ || quit
  REPLY_=${REPLY_//$'\r'/}
  REPLY_=${REPLY_#"${REPLY_%%[![:space:]]*}"}; REPLY_=${REPLY_%"${REPLY_##*[![:space:]]}"}
}
pause() { ask "${DIM}${1:-Enter to continue}${RESET}"; }

# ── progress ───────────────────────────────────────────────────────────────
NAME=""; STEP=1; XP=0; BADGES=""; DONE=","; READ=","; QUIZ=","; SEEN=","; QFIRST=0; STREAK=0; START=0
save() {
  { printf 'NAME=%q\nSTEP=%q\nXP=%q\nBADGES=%q\n' "$NAME" "$STEP" "$XP" "$BADGES"
    printf 'DONE=%q\nREAD=%q\nQUIZ=%q\nSEEN=%q\n' "$DONE" "$READ" "$QUIZ" "$SEEN"
    printf 'QFIRST=%q\nSTREAK=%q\nSTART=%q\n' "$QFIRST" "$STREAK" "$START"; } > "$PROG" 2>/dev/null || true
}
load() { [[ -f "$PROG" ]] && . "./$PROG"; return 0; }
quit() {
  save
  printf '\n\n  Saved at step %s with %s XP. Run  bash start.sh  to continue.\n\n' "$STEP" "$XP"
  [[ -n "${WORKSHOP_LAUNCHER:-}" ]] && { printf '  Press Enter to close this window. '; read -r _ || true; }
  exit 0
}
trap quit INT

# ── step texts ─────────────────────────────────────────────────────────────
stepfile() { printf 'steps/%02d.txt' "$1"; }
field()    { tr -d '\r' < "$(stepfile "$1")" | sed -n "s/^$2: //p" | head -n 1; }
section()  { awk -v want="[$2]" '{ sub(/\r$/, "") } $0 == want { on = 1; next } /^\[[a-z]+\]$/ { on = 0 } on' "$(stepfile "$1")"; }
render() {
  local nm=${NAME:-<your name>}
  sed -e "s/{NAME}/$nm/g" -e "s/{FOLDER}/$FOLDER/g" -e "s/{FILE}/$FILE/g" \
      -e "s/\*\*\([^*]*\)\*\*/$BOLD\1$RESET/g" -e "s/^- /$PURPLE$ARW$RESET /" -e 's/^/  /' | asciify
}
act_of() { if (($1 <= 3)); then echo "ACT 1 $DOT THE DATA"; elif (($1 <= 7)); then echo "ACT 2 $DOT THE FLOW"; else echo "ACT 3 $DOT THE AGENT"; fi; }

# ── XP, levels, badges ─────────────────────────────────────────────────────
# Messages go straight to the screen, or into TOAST when the screen is about to be redrawn.
TOAST=""; QUIET=0
msg() { if ((QUIET)); then TOAST+="$1"$'\n'; else printf '%s\n' "$1"; fi; }
level() { local i=0; while ((i + 1 < ${#LEVELS[@]} && XP >= LEVELS[i + 1])); do i=$((i + 1)); done; LV=$i; }
award() {
  local before; level; before=$LV
  XP=$((XP + $1)); level
  msg "  $GREEN$BOLD+$1 XP$RESET  $DIM$2$RESET"
  if ((LV > before)); then
    msg ""
    msg "  $PURPLE$BOLD$STAR$STAR$STAR  LEVEL UP  ${TITLES[before]} $ARW ${TITLES[LV]}  $STAR$STAR$STAR$RESET"
    ((LV == ${#LEVELS[@]} - 1)) && badge P
  fi
  save
}
badge() {
  case "$BADGES" in *"$1"*) return 0 ;; esac
  BADGES+=$1
  msg ""
  msg "  $YELLOW$BOLD$STAR BADGE UNLOCKED: $(badge_name "$1")$RESET  $DIM$(badge_why "$1")$RESET"
  award 50 "badge bonus"
}
read_reward() {
  case "$READ" in *",$1$STEP,"*) return 0 ;; esac
  READ+="$1$STEP,"; QUIET=1; award 10 "curiosity"
  local n; n=$(printf '%s' "$READ" | tr -cd ',' | wc -c); ((n - 1 >= 2 * TOTAL)) && badge C
  QUIET=0
}

stepbar() {
  local i s=""
  for ((i = 1; i <= TOTAL; i++)); do
    if ((i == STEP)); then s+="$PURPLE$CUR$RESET"; elif [[ "$DONE" == *",$i,"* ]]; then s+="$PURPLE$ON$RESET"; else s+="$DIM$OFF$RESET"; fi
  done
  printf '%s' "$s"
}
xpbar() {
  local lo hi i n s=""; level
  if ((LV == ${#LEVELS[@]} - 1)); then n=16; else lo=${LEVELS[LV]}; hi=${LEVELS[LV + 1]}; n=$(((XP - lo) * 16 / (hi - lo))); fi
  for ((i = 0; i < 16; i++)); do if ((i < n)); then s+=$FULL; else s+=$EMPTY; fi; done
  printf '%s%s%s' "$PURPLE" "$s" "$RESET"
}
badgeline() {
  local i c s=""
  for ((i = 0; i < ${#BADGE_ORDER}; i++)); do c=${BADGE_ORDER:i:1}; case "$BADGES" in *"$c"*) s+="$YELLOW$STAR$RESET" ;; *) s+="$DIM$NOSTAR$RESET" ;; esac; done
  printf '%s' "$s"
}

# ── laptop helpers (Windows first, macOS for facilitators) ─────────────────
winpath() { if command -v cygpath >/dev/null 2>&1; then cygpath -w "$1"; else printf '%s' "$1"; fi; }
open_url() {
  ((TEST)) && return 0
  { if command -v explorer.exe >/dev/null 2>&1; then explorer.exe "$1"
    elif command -v open >/dev/null 2>&1; then open "$1"
    elif command -v xdg-open >/dev/null 2>&1; then xdg-open "$1"; fi; } >/dev/null 2>&1 || true
}
open_path() { open_url "$(winpath "$1")"; }

# clip FILE: PowerShell keeps accents and quotes intact; clip.exe only does with UTF-16 and a BOM.
clip() {
  ((TEST)) && return 0
  if command -v powershell.exe >/dev/null 2>&1; then
    powershell.exe -NoProfile -NonInteractive -Command \
      "Set-Clipboard -Value ([IO.File]::ReadAllText('$(winpath "$1")', [Text.Encoding]::UTF8))" >/dev/null 2>&1 && return 0
  fi
  if command -v clip.exe >/dev/null 2>&1 && command -v iconv >/dev/null 2>&1; then
    { printf '\377\376'; iconv -f UTF-8 -t UTF-16LE "$1"; } | clip.exe 2>/dev/null && return 0
  fi
  command -v pbcopy >/dev/null 2>&1 && pbcopy < "$1" && return 0
  return 1
}

# OneDrive for Business: the Windows variable first, then the "OneDrive - <company>" folder.
onedrive_dir() {
  local d
  for d in "${WORKSHOP_ONEDRIVE:-}" "${OneDriveCommercial:-}" "${OneDrive:-}"; do
    [[ -z "$d" ]] && continue
    command -v cygpath >/dev/null 2>&1 && d=$(cygpath -u "$d")
    [[ -d "$d" ]] && { printf '%s' "$d"; return 0; }
  done
  for d in "$HOME"/OneDrive\ -\ *; do [[ -d "$d" ]] && { printf '%s' "$d"; return 0; }; done
  return 1
}

# ── the screen ─────────────────────────────────────────────────────────────
tab() { # key label panel reward-key
  local mark=""
  [[ -n "$4" && "$READ" != *",$4$STEP,"* ]] && mark=" $GREEN+10$RESET"
  if [[ "$PANEL" == "$3" ]]; then printf '%s%s %s %s%s%s  ' "$REV" "$PURPLE" "$2" "$RESET" "$mark" ""
  else printf '%s%s%s %s%s  ' "$DIM" "$1" "$RESET" "$2" "$mark"; fi
}
draw() {
  cls
  level
  printf '\n  %s%s%s GT AGENT WORKSHOP%s' "$BOLD" "$PURPLE" "$CUP" "$RESET"
  [[ -n "$NAME" ]] && printf '   %sBarista %s%s' "$DIM" "$NAME" "$RESET"
  printf '\n  %s %s%2s/%s%s   %s%s%s %s %s XP   %s\n' "$(stepbar)" "$DIM" "$STEP" "$TOTAL" "$RESET" \
    "$BOLD" "${TITLES[LV]}" "$RESET" "$(xpbar)" "$XP" "$(badgeline)"
  hr
  printf '  %s%s%s\n' "$PURPLE" "$(act_of "$STEP")" "$RESET"
  printf '  %sStep %s %s %s%s\n\n' "$BOLD" "$STEP" "$DOT" "$(field "$STEP" title | asciify)" "$RESET"
  printf '  '; tab d "Do" do ""; tab w "Why" why w; tab i "Inside" what i; tab h "Stuck?" help ""; printf '\n\n'
  case "$PANEL" in
    do)   section "$STEP" do | render ;;
    why)  section "$STEP" why | render ;;
    what) section "$STEP" what | render ;;
    help) section "$STEP" help | render
          printf '\n'; note "More: TROUBLESHOOTING.md, or quit and run  bash start.sh doctor" ;;
  esac
  [[ -n "$TOAST" ]] && { printf '\n%s' "$TOAST"; TOAST=""; }
  printf '\n'; hr
  if [[ "$PANEL" == do ]]; then
    printf '  %sEnter%s step done  %sw%s why  %si%s inside  %sh%s stuck  %sg%s guide  %sb%s back  %sq%s quit\n' \
      "$BOLD" "$RESET" "$BOLD" "$RESET" "$BOLD" "$RESET" "$BOLD" "$RESET" "$BOLD" "$RESET" "$BOLD" "$RESET" "$BOLD" "$RESET"
  else
    printf '  %sEnter%s back to the steps  %sw%s why  %si%s inside  %sh%s stuck  %sq%s quit\n' \
      "$BOLD" "$RESET" "$BOLD" "$RESET" "$BOLD" "$RESET" "$BOLD" "$RESET" "$BOLD" "$RESET"
  fi
}

intro() {
  case "$SEEN" in *",$STEP,"*) return 0 ;; esac
  SEEN+="$STEP,"; save
  local text first i
  text=$(section "$STEP" intro); [[ -z "$text" ]] && return 0
  first=$(printf '%s\n' "$text" | head -n 1 | asciify)
  cls; printf '\n\n\n  %s%s' "$BOLD" "$PURPLE"
  for ((i = 0; i < ${#first}; i++)); do printf '%s' "${first:i:1}"; nap 0.03; done
  printf '%s\n' "$RESET"
  printf '%s\n' "$text" | tail -n +2 | render
  printf '\n\n'; pause "Enter to start"
}

# ── what Enter does on each step ───────────────────────────────────────────
ask_name() {
  while [[ -z "$NAME" ]]; do
    ask "What's your first name? (q quits)"
    [[ "$REPLY_" == [qQ] ]] && quit
    NAME=$(printf '%s' "$REPLY_" | tr -cd 'A-Za-z0-9 -' | cut -c 1-20)
    NAME=${NAME%% }
  done
  ((START > 0)) || START=$(date +%s)
  good "Hello, $NAME. Your agent will be called Barista $NAME."
}

copy_data() {
  local od dest
  if od=$(onedrive_dir); then
    dest="$od/$FOLDER"
    if [[ -f "$dest/$FILE" ]]; then
      good "$FILE is already in your OneDrive. Kept it as it is."
    elif mkdir -p "$dest" && cp "data/$FILE" "$dest/$FILE"; then
      good "Copied to $(winpath "$dest/$FILE")"
      say "OneDrive uploads it now. It's in the cloud within about 30 seconds."
    else
      warn "Copy failed. Press h on this step for the fixes."; pause; return 1
    fi
  else
    warn "I can't find OneDrive on this laptop. Upload it by hand, it works just as well:"
    say "$ARW Browser (opening now): OneDrive, ${BOLD}+ Nieuw$RESET → ${BOLD}Map$RESET → $FOLDER"
    say "$ARW Open the folder: ${BOLD}Uploaden$RESET → ${BOLD}Bestanden$RESET → data/$FILE (Explorer opens it)"
    open_url "https://gtnl-my.sharepoint.com"; open_path "$PWD/data"
    pause "Enter once the file is uploaded"
  fi
}

copy_instructions() {
  if clip "data/instructies.txt"; then
    good "The instructions are on your clipboard. Paste them with Ctrl+V."
  else
    warn "Couldn't reach the clipboard. Select this text and copy it (Ctrl+Insert in Git Bash):"
    sed 's/^/    /' data/instructies.txt
  fi
}

quiz() {
  case "$QUIZ" in *",$STEP,"*) return 0 ;; esac
  local q question answer because try=1 a
  q=$(section "$STEP" quiz); [[ -z "$q" ]] && return 0
  question=$(printf '%s\n' "$q" | head -n 1)
  answer=$(printf '%s\n' "$q" | sed -n 's/^answer: //p')
  because=$(printf '%s\n' "$q" | sed -n 's/^because: //p')
  printf '\n  %s%sQUIZ%s  %s+50 XP first try, +20 second%s\n' "$REV" "$PURPLE" "$RESET" "$DIM" "$RESET"
  printf '  %s%s%s\n' "$BOLD" "$(printf '%s' "$question" | asciify)" "$RESET"
  printf '%s\n' "$q" | grep -E '^[abc]\) ' | sed 's/^/     /' | asciify
  while ((try <= 2)); do
    ask "a, b or c?"
    case "$REPLY_" in [aA]*) a=a ;; [bB]*) a=b ;; [cC]*) a=c ;; *) say "Type a, b or c."; continue ;; esac
    if [[ "$a" == "$answer" ]]; then
      if ((try == 1)); then
        QFIRST=$((QFIRST + 1)); STREAK=$((STREAK + 1))
        award 50 "right first time"
        if ((STREAK > 1)); then local bonus=$((10 * (STREAK - 1))); ((bonus > 50)) && bonus=50; award "$bonus" "streak x$STREAK"; fi
      else
        STREAK=0; award 20 "right the second time"
      fi
      break
    fi
    if ((try == 1)); then warn "Not quite. One more try."; else STREAK=0; warn "It's $answer."; fi
    try=$((try + 1))
  done
  note "$(printf '%s' "$because" | asciify)"
  QUIZ+="$STEP,"; save
}

# gate STEP QUESTION ANSWER XP BADGE: code checks a number the participant read off the screen.
gate() {
  local want=$3 xp=$4 tries=0 got
  printf '\n  %s%sCHECK%s  %s+%s XP if it matches what the file says%s\n' "$REV" "$PURPLE" "$RESET" "$DIM" "$xp" "$RESET"
  while true; do
    ask "$2"
    [[ -z "$REPLY_" ]] && return 1
    [[ "$REPLY_" == skip ]] && { warn "Skipped. The right answer was $want."; return 0; }
    got=${REPLY_//[^0-9]/}; tries=$((tries + 1))
    if [[ "$got" == "$want" ]] || [[ "$1" == 13 && "$got" == $((want + 1)) ]]; then
      good "$got is right. That's what the file says."
      ((tries > 1)) && xp=$((xp / 2))
      award "$xp" "checked by code"; [[ -n "$5" ]] && badge "$5"
      return 0
    fi
    case "$1:$got" in
      15:"$(expected cappuccino)") warn "That's the count from before your row. Is the row inside the table? New test chat, ask again." ;;
      7:0|13:0|15:0) warn "0 means the filter matched nothing: check the quotes and spelling in step 6." ;;
      13:*|15:*) warn "Not what the file says. Did the activity map show Koffie tellen? If not, see step 9." ;;
      *) warn "Not what the file says. Count the {...} blocks in value again, or check the filter." ;;
    esac
    say "Try again, press Enter to go back to the step, or type skip."
  done
}

finish_step() {
  printf '\n'
  case "$STEP" in
    1) ask_name ;;
    2) copy_data || return 1 ;;
    8) copy_instructions ;;
  esac
  case "$STEP" in
    7)  gate 7 "How many rows did the flow return for cappuccino?" "$(expected cappuccino)" 100 F || return 1 ;;
    13) gate 13 "What number did the agent give for cappuccino?" "$(expected cappuccino)" 100 "" || return 1 ;;
    15) gate 15 "How many cappuccinos did the agent say after your new row?" $(($(expected cappuccino) + 1)) 250 L || return 1 ;;
    *)  quiz ;;
  esac
  case "$DONE" in *",$STEP,"*) ;; *) DONE+="$STEP,"; printf '\n'; award 100 "step $STEP done" ;; esac
  case "$STEP" in 3) badge D ;; 12) badge A ;; esac
  save
  ((STEP == TOTAL)) || { printf '\n'; pause "Enter for step $((STEP + 1))"; }
  return 0
}

finale() {
  local mins=0 line tmp i c
  ((START > 0)) && mins=$((($(date +%s) - START) / 60))
  ((START > 0 && mins <= 40)) && badge S
  ((QFIRST >= QUIZZES)) && badge Q
  nap 1; cls; level
  printf '\n\n  %s%s%s  Barista %s, take a bow.%s\n\n' "$BOLD" "$PURPLE" "$CUP" "$NAME" "$RESET"
  say "You built an agent from an empty folder. The flow counted, the agent"
  say "explained, and code checked it. GT agents are built the same way."
  printf '\n'; hr
  printf '  %-10s %s%s%s\n' "Level" "$BOLD" "${TITLES[LV]}" "$RESET"
  printf '  %-10s %s\n' "XP" "$XP"
  printf '  %-10s %s min\n' "Time" "$mins"
  printf '  %-10s %s of %s right the first time\n' "Quizzes" "$QFIRST" "$QUIZZES"
  printf '  %-10s %s of %s\n\n' "Badges" "${#BADGES}" "${#BADGE_ORDER}"
  for ((i = 0; i < ${#BADGE_ORDER}; i++)); do
    c=${BADGE_ORDER:i:1}
    case "$BADGES" in
      *"$c"*) printf '  %s%s%s %-14s %s\n' "$YELLOW" "$STAR" "$RESET" "$(badge_name "$c")" "$(badge_why "$c")" ;;
      *)      printf '  %s%s %-14s %s%s\n' "$DIM" "$NOSTAR" "$(badge_name "$c")" "$(badge_why "$c")" "$RESET" ;;
    esac
  done
  hr
  line="Barista $NAME $DOT ${TITLES[LV]} $DOT $XP XP $DOT ${#BADGES}/${#BADGE_ORDER} badges $DOT $mins min"
  tmp=$(mktemp 2>/dev/null || echo ".score.txt"); printf '%s\n' "$line" > "$tmp"
  if clip "$tmp"; then say "Post your score in the workshop chat. It's on your clipboard:"; else say "Post your score in the workshop chat:"; fi
  printf '  %s%s%s\n\n' "$BOLD" "$line" "$RESET"
  rm -f "$tmp"
  say "Run it again any time: bash start.sh --step 1"
  [[ -n "${WORKSHOP_LAUNCHER:-}" ]] && { printf '\n'; pause "Enter to close"; }
  printf '\n'
}

# ── doctor: check the laptop, print the fix next to each problem ───────────
doctor() {
  local n=0 od cols lines cr
  row() { if [[ "$1" == 0 ]]; then printf '  %s%s%s %-14s %s\n' "$GREEN" "$OK" "$RESET" "$2" "$3"
          else n=$((n + 1)); printf '  %s!%s %-14s %s\n                 %s%s%s\n' "$YELLOW" "$RESET" "$2" "$3" "$DIM" "$4" "$RESET"; fi; }
  printf '\n  %s%s doctor%s\n\n' "$BOLD" "$CUP" "$RESET"
  case "$(uname -s)" in
    MINGW*|MSYS*) row 0 "Shell" "Git Bash, bash $BASH_VERSION" ;;
    Darwin)       row 0 "Shell" "macOS, bash $BASH_VERSION (fine for facilitators)" ;;
    *)            row 1 "Shell" "$(uname -s)" "Run this in Git Bash: right-click the folder, Open Git Bash here." ;;
  esac
  if [[ ! -f "data/$FILE" ]]; then row 1 "Folder" "data/$FILE is missing" "Extract the zip first (right-click, Extract All), then run it from that folder."
  elif [[ "$PWD" == */Temp/* || "$PWD" == */AppData/Local/Temp* ]]; then row 1 "Folder" "running from a temp folder" "You opened it inside the zip. Extract All first."
  else row 0 "Folder" "$(winpath "$PWD")"; fi
  if touch .doctor 2>/dev/null; then rm -f .doctor; row 0 "Progress" "can save in this folder"
  else row 1 "Progress" "can't write here" "Move the folder to Downloads or Documents."; fi
  cr=$(cat start.sh steps/*.txt | tr -cd '\r' | wc -c | tr -d ' ')
  if [[ "$cr" == 0 ]]; then row 0 "Line endings" "Unix (LF)"
  else row 1 "Line endings" "Windows (CRLF) in the files" "Works anyway with: bash -o igncr start.sh  (start.cmd does this)"; fi
  if od=$(onedrive_dir); then row 0 "OneDrive" "$(winpath "$od")"
  else row 1 "OneDrive" "not found" "Sign in to the OneDrive app, or upload by hand in step 2. Both work."; fi
  if command -v powershell.exe >/dev/null 2>&1; then row 0 "Clipboard" "PowerShell"
  elif command -v clip.exe >/dev/null 2>&1; then row 0 "Clipboard" "clip.exe"
  elif command -v pbcopy >/dev/null 2>&1; then row 0 "Clipboard" "pbcopy"
  else row 1 "Clipboard" "none" "Step 8 prints the text instead; copy it by hand."; fi
  if command -v explorer.exe >/dev/null 2>&1 || command -v open >/dev/null 2>&1; then row 0 "Browser" "can open links"
  else row 1 "Browser" "can't open links" "Open the links on screen by hand."; fi
  cols=$(tput cols 2>/dev/null || echo 80); lines=$(tput lines 2>/dev/null || echo 24)
  if ((cols >= 76 && lines >= 30)); then row 0 "Window" "${cols} x ${lines}"
  else row 1 "Window" "${cols} x ${lines}" "Drag the window bigger: about 100 x 34."; fi
  if [[ "$(locale charmap 2>/dev/null)" == UTF-8 ]]; then row 0 "Characters" "UTF-8: ─ $OK $STAR → should look right"
  else row 1 "Characters" "$(locale charmap 2>/dev/null || echo unknown)" "Use: bash start.sh --ascii"; fi
  if [[ -f "$PROG" ]]; then load; row 0 "Progress" "step $STEP, $XP XP, name '${NAME}'"; fi
  printf '\n'
  if ((n == 0)); then good "All good. Start with: bash start.sh"; else warn "$n thing(s) to look at. The fix is under each one."; fi
  printf '\n'
}

usage() {
  sed -n '3,10p' start.sh | sed 's/^# \{0,1\}//'
  printf '\nKeys: Enter = step done, w = why, i = inside, h = stuck, g = guide, b = back, q = quit (saved).\n'
}

# ── main ───────────────────────────────────────────────────────────────────
case "$MODE" in
  help)   usage; exit 0 ;;
  doctor) doctor; exit 0 ;;
  reset)  ask "Wipe your progress and XP? Type yes:"; [[ "$REPLY_" == yes ]] && rm -f "$PROG" && good "Wiped. Run: bash start.sh"; exit 0 ;;
esac
if [[ ! -f "data/$FILE" || ! -d steps ]]; then
  printf '\n  data/%s is missing. Extract the zip first (right-click, Extract All),\n  then run bash start.sh from the extracted folder.\n\n' "$FILE"
  exit 1
fi
# mintty (Git Bash) accepts a resize request; other terminals ignore it.
[[ "${TERM_PROGRAM:-}" == mintty && -t 1 && "$(tput lines 2>/dev/null || echo 99)" -lt 34 ]] && printf '\033[8;34;100t'

load
if [[ -n "$JUMP" ]]; then
  if [[ "$JUMP" =~ ^[0-9]+$ ]] && ((JUMP >= 1 && JUMP <= TOTAL)); then STEP=$JUMP; else printf 'Pick a step from 1 to %s.\n' "$TOTAL"; exit 2; fi
fi
((STEP >= 1 && STEP <= TOTAL)) || STEP=1
[[ -z "$NAME" ]] && STEP=1
PANEL=do; OPENED=","

while true; do
  intro
  case "$OPENED" in *",$STEP,"*) ;; *) OPENED+="$STEP,"; url=$(field "$STEP" open); [[ -n "$url" ]] && open_url "$url" ;; esac
  draw
  printf '  %s>%s ' "$PURPLE" "$RESET"
  IFS= read -r key || quit
  key=${key//$'\r'/}; key=${key// /}
  case "$key" in
    q|Q) quit ;;
    w|W) PANEL=why; read_reward w ;;
    i|I) PANEL=what; read_reward i ;;
    h|H) PANEL=help ;;
    d|D) PANEL=do ;;
    g|G) open_path "$PWD/guide/index.html"; TOAST="  ${DIM}Opened the guide in your browser: scroll to step $STEP.$RESET"$'\n' ;;
    b|B) PANEL=do; ((STEP > 1)) && STEP=$((STEP - 1)); save ;;
    "")
      if [[ "$PANEL" != do ]]; then PANEL=do; continue; fi
      finish_step || continue
      if ((STEP == TOTAL)); then finale; exit 0; fi
      STEP=$((STEP + 1)); save ;;
    *) TOAST="  ${YELLOW}Unknown key '$key'. Use Enter, w, i, h, g, b or q.$RESET"$'\n' ;;
  esac
done
