"""Build guide/index.html from steps/*.txt and TROUBLESHOOTING.md.

The step files are the single source: the wizard shows them in Git Bash, this script turns the same
text into the visual guide. Run after editing a step:   python3 tools/build-guide.py
"""
import html
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
ACTS = {1: ("Act 1", "The data", "SharePoint · OneDrive · Excel"),
        4: ("Act 2", "The flow", "Power Automate"),
        8: ("Act 3", "The agent", "Copilot Studio, classic")}
SHOTS = {8: ("shot_topic.png", "A topic in the classic authoring canvas: every part of the agent is visible."),
         11: ("shot_flow.png", "An agent flow in the designer: a trigger, steps, and an answer back to the agent."),
         13: ("shot_map.png", "The activity map: which tool the agent picked, and with which inputs.")}


def parse(path):
    meta, sec, cur = {}, {}, None
    for line in path.read_text(encoding="utf-8").replace("\r", "").splitlines():
        m = re.fullmatch(r"\[([a-z]+)\]", line)
        if m:
            cur = m.group(1); sec[cur] = []
        elif cur is None and ": " in line:
            k, v = line.split(": ", 1); meta[k] = v
        elif cur:
            sec[cur].append(line)
    return meta, sec


def inline(s):
    s = html.escape(s, quote=False)
    s = s.replace("{NAME}", "<i>your name</i>").replace("{FOLDER}", "GT-Agent-Workshop").replace("{FILE}", "koffie.xlsx")
    s = re.sub(r"\*\*(.+?)\*\*", r"<b>\1</b>", s)
    return s


def block(lines):
    """Step text → HTML: '- ' lines are a list, 3+ space indents are pre blocks, the rest paragraphs."""
    out, para, items, pre = [], [], [], []

    def flush():
        if para: out.append("<p>" + " ".join(inline(x) for x in para) + "</p>"); para.clear()
        if items: out.append("<ul>" + "".join(f"<li>{x}</li>" for x in items) + "</ul>"); items.clear()
        if pre: out.append("<pre>" + inline("\n".join(pre)) + "</pre>"); pre.clear()

    for line in lines:
        if not line.strip():
            flush()
        elif line.startswith("- "):
            if para or pre: flush()
            items.append(inline(line[2:]))
        elif line.startswith("  ") and not line.startswith("   ") and items:
            items[-1] += " " + inline(line.strip())
        elif line.startswith("   "):
            if para or items: flush()
            pre.append(line[3:] if line.startswith("   ") else line)
        else:
            if items or pre: flush()
            para.append(line)
    flush()
    return "\n".join(out)


# ── diagrams: hairlines, ticks and labels, as in the deck ──────────────────
def stations(labels, subs, w=880, accent_upto=None):
    n = len(labels); x0, x1, y = 100, w - 100, 46
    step = (x1 - x0) / (n - 1)
    parts = [f'<line x1="{x0}" y1="{y}" x2="{x1}" y2="{y}" class="rail"/>',
             f'<line x1="{x0}" y1="{y}" x2="{x1 if accent_upto is None else x0 + step * accent_upto}" y2="{y}" class="seg"/>']
    for i, (a, b) in enumerate(zip(labels, subs)):
        x = x0 + step * i
        parts.append(f'<line x1="{x}" y1="{y - 7}" x2="{x}" y2="{y + 7}" class="tick"/>')
        parts.append(f'<text x="{x}" y="{y - 18}" class="lab">{a}</text>')
        parts.append(f'<text x="{x}" y="{y + 28}" class="sub">{b}</text>')
    return f'<svg viewBox="0 0 {w} 90" role="img" aria-label="{" to ".join(labels)}">{"".join(parts)}</svg>'


def fan():
    trig = [("Handmatig", "you press a button"), ("Planning", "every Monday 07:00"),
            ("Automatisch", "a new e-mail or file"), ("Agent", "an agent calls it")]
    p = []
    for i, (a, b) in enumerate(trig):
        y = 24 + i * 46
        cls = "seg" if i in (0, 3) else "rail"
        p.append(f'<text x="0" y="{y + 4}" class="lab l">{a}</text><text x="0" y="{y + 20}" class="sub l">{b}</text>')
        p.append(f'<path d="M150 {y} C 260 {y}, 280 93, 380 93" class="{cls}" fill="none"/>')
    p.append('<line x1="380" y1="80" x2="380" y2="106" class="tick"/>')
    p.append('<text x="392" y="88" class="lab l">Flow</text><text x="392" y="104" class="sub l">same input, same output</text>')
    p.append('<line x1="560" y1="93" x2="700" y2="93" class="seg"/><line x1="700" y1="80" x2="700" y2="106" class="tick"/>')
    p.append('<text x="712" y="88" class="lab l">Result</text><text x="712" y="104" class="sub l">a number, a file, a mail</text>')
    return f'<svg viewBox="0 0 880 196" role="img" aria-label="Four kinds of trigger start the same flow">{"".join(p)}</svg>'


def loop():
    xs = [60, 230, 400, 570, 740]
    labels = ["Question", "Agent", "Koffie tellen", "Agent flow", "Excel table"]
    subs = ["Hoeveel cappuccino's?", "plans, picks a tool", "tool + description", "length(value)", "OneDrive · Bestellingen"]
    p = [f'<line x1="60" y1="40" x2="740" y2="40" class="seg"/>',
         '<path d="M740 40 L740 110 L230 110 L230 40" class="rail dash" fill="none"/>',
         '<text x="485" y="128" class="sub">aantal: 8 comes back · the agent explains it</text>']
    for x, a, b in zip(xs, labels, subs):
        p.append(f'<line x1="{x}" y1="33" x2="{x}" y2="47" class="tick"/><text x="{x}" y="20" class="lab">{a}</text>')
        p.append(f'<text x="{x}" y="66" class="sub">{b}</text>')
    return f'<svg viewBox="0 0 800 140" role="img" aria-label="The question goes to the agent, the tool, the flow and the Excel table; the number comes back">{"".join(p)}</svg>'


def two_flows():
    p = []
    for y, a, b, c in [(34, "Handmatig flow", "you press Testen", "you read the output"),
                       (104, "Agent flow", "Wanneer een agent de stroom aanroept", "Reageren op de agent")]:
        p.append(f'<text x="0" y="{y - 14}" class="lab l">{a}</text>')
        p.append(f'<line x1="0" y1="{y}" x2="800" y2="{y}" class="rail"/>')
        p.append(f'<line x1="300" y1="{y}" x2="540" y2="{y}" class="seg"/>')
        for x, t in [(0, b), (300, "Excel: rows for drankje"), (540, "count"), (800, c)]:
            anchor = "e" if x == 800 else "l"
            p.append(f'<line x1="{x}" y1="{y - 6}" x2="{x}" y2="{y + 6}" class="tick"/>'
                     f'<text x="{x}" y="{y + 22}" class="sub {anchor}">{t}</text>')
    return f'<svg viewBox="-2 0 806 140" role="img" aria-label="Two flows with the same Excel step and different start and end">{"".join(p)}</svg>'


def ladder():
    lv = [(0, "Trainee"), (400, "Assistant"), (1000, "Senior"), (1600, "Manager"), (2300, "Director"), (3000, "Partner")]
    p = ['<line x1="40" y1="40" x2="840" y2="40" class="rail"/><line x1="40" y1="40" x2="840" y2="40" class="seg grow"/>']
    for xp, name in lv:
        x = 40 + xp / 3000 * 800
        p.append(f'<line x1="{x}" y1="33" x2="{x}" y2="47" class="tick"/><text x="{x}" y="22" class="lab">{name}</text>'
                 f'<text x="{x}" y="68" class="sub">{xp} XP</text>')
    return f'<svg viewBox="0 0 880 80" role="img" aria-label="Levels from Trainee to Partner">{"".join(p)}</svg>'


DIAGRAMS = {
    1: ('<figure class="dia">' + stations(["Site", "Library", "Folder", "File", "Agent"],
                                          ["gtnl-my.sharepoint.com", "OneDrive", "GT-Agent-Workshop", "koffie.xlsx", "Barista"])
        + '<figcaption>The folder you connect is where the agent is born.</figcaption></figure>'),
    4: '<figure class="dia">' + fan() + '<figcaption>Four kinds of trigger. Today you use Handmatig, then Agent.</figcaption></figure>',
    8: ('<figure class="dia">' + loop() + '<figcaption>Code calculates, the LLM explains.</figcaption></figure>'
        '<figure class="dia">' + two_flows() + '<figcaption>Why you build the count twice: the steps are the same, the start and the end differ.</figcaption></figure>'),
}


ANCHORS = {"TROUBLESHOOTING.md": "#troubleshooting", "GIT-BASH.md": "#git-bash"}


def md_section(name):
    """The small part of Markdown the docs use: headings, paragraphs, lists, tables, code blocks, links."""
    md = (ROOT / name).read_text(encoding="utf-8").splitlines()
    out, buf, kind, in_code = [], [], None, False

    def md_inline(s):
        s = html.escape(s, quote=False)
        s = re.sub(r"`([^`]+)`", r"<code>\1</code>", s)
        s = re.sub(r"\[([^\]]+)\]\(([^)]+)\)", lambda m: f'<a href="{ANCHORS.get(m.group(2), m.group(2))}">{m.group(1)}</a>', s)
        return re.sub(r"\*\*(.+?)\*\*", r"<b>\1</b>", s)

    def flush():
        nonlocal kind
        if kind == "p": out.append("<p>" + " ".join(md_inline(x) for x in buf) + "</p>")
        elif kind in ("ul", "ol"): out.append(f"<{kind}>" + "".join(f"<li>{md_inline(x)}</li>" for x in buf) + f"</{kind}>")
        elif kind == "table":
            rows = [[c.strip() for c in r.strip("|").split("|")] for r in buf if not re.fullmatch(r"[|\- ]+", r)]
            head = "".join(f"<th>{md_inline(c)}</th>" for c in rows[0])
            body = "".join("<tr>" + "".join(f"<td>{md_inline(c)}</td>" for c in r) + "</tr>" for r in rows[1:])
            out.append(f'<table class="md"><tr>{head}</tr>{body}</table>')
        elif kind == "pre": out.append("<pre>" + html.escape("\n".join(buf)) + "</pre>")
        buf.clear(); kind = None

    def add(k, s):
        nonlocal kind
        if kind != k: flush(); kind = k
        buf.append(s)

    for line in md[1:]:
        if line.startswith("```"):
            if in_code: flush()
            else: flush(); kind = "pre"
            in_code = not in_code
        elif in_code: buf.append(line)
        elif line.startswith("## "): flush(); out.append(f"<h3>{md_inline(line[3:])}</h3>")
        elif line.startswith("### "): flush(); out.append(f"<h4>{md_inline(line[4:])}</h4>")
        elif line.startswith("- "): add("ul", line[2:])
        elif re.match(r"\d+\. ", line): add("ol", line.split(". ", 1)[1])
        elif line.startswith("|"): add("table", line)
        elif line.startswith("  ") and kind in ("ul", "ol"): buf[-1] += " " + line.strip()
        elif not line.strip(): flush()
        else: add("p", line)
    flush()
    return "\n".join(out)


def step_html(n, meta, sec):
    quiz = ""
    if sec.get("quiz"):
        q = sec["quiz"]
        opts = [l for l in q if re.match(r"^[abc]\) ", l)]
        ans = next(l.split(": ", 1)[1] for l in q if l.startswith("answer: "))
        because = next(l.split(": ", 1)[1] for l in q if l.startswith("because: "))
        buttons = "".join(f'<button type="button" data-ok="{int(o[0] == ans)}"><span>{o[0]}</span>{inline(o[3:])}</button>' for o in opts)
        quiz = (f'<div class="quiz"><div class="k">Quiz · +50 XP in the wizard</div><p class="q">{inline(q[0])}</p>'
                f'<div class="opts">{buttons}</div><p class="because" hidden>{inline(because)}</p></div>')
    shot = ""
    if n in SHOTS:
        f, cap = SHOTS[n]
        shot = f'<figure class="shot"><img src="img/{f}" alt="{html.escape(cap)}" loading="lazy"><figcaption>{cap} Example from Microsoft Learn.</figcaption></figure>'
    return f"""
<section class="step" id="step-{n}">
  <div class="num">{n:02d}</div>
  <div class="body">
    <h3>{inline(meta["title"])}</h3>
    <div class="do"><div class="k">Do</div>{block(sec.get("do", []))}</div>
    <div class="cols">
      <div><div class="k">Why</div>{block(sec.get("why", []))}</div>
      <div><div class="k">Inside</div>{block(sec.get("what", []))}</div>
    </div>
    {shot}{quiz}
    <details><summary>Stuck?</summary>{block(sec.get("help", []))}</details>
  </div>
</section>"""


def main():
    steps = [(int(p.stem), *parse(p)) for p in sorted((ROOT / "steps").glob("[0-9][0-9].txt"))]
    icon = lambda f, a: f'<img src="img/{f}" alt="{a}" width="56" height="56">'
    body = []
    for n, meta, sec in steps:
        if n in ACTS:
            eb, title, tool = ACTS[n]
            intro = [l for l in sec.get("intro", [])[1:] if not l.startswith("   ")]
            body.append(f'<header class="act" id="act-{list(ACTS).index(n) + 1}"><div class="eb">{eb} · {tool}</div>'
                        f'<h2>{title}.</h2>{block(intro)}{DIAGRAMS[n]}</header>')
        body.append(step_html(n, meta, sec))
    nav = "".join(f'<a href="#step-{n}">{n}</a>' for n, _, _ in steps)
    page = TEMPLATE.replace("__NAV__", nav).replace("__STEPS__", "\n".join(body)) \
        .replace("__LADDER__", ladder()).replace("__TROUBLE__", md_section("TROUBLESHOOTING.md")).replace("__GITBASH__", md_section("GIT-BASH.md")) \
        .replace("__ICONS__", icon("sharepoint.svg", "SharePoint") + '<i></i>' + icon("excel.svg", "Excel") + '<i></i>'
                 + icon("power-automate.svg", "Power Automate") + '<i></i>' + icon("copilot-studio.svg", "Copilot Studio"))
    (ROOT / "guide" / "index.html").write_text(page, encoding="utf-8")
    print(f"guide/index.html: {len(steps)} steps, {len(page) // 1024} KB")


TEMPLATE = """<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>Build a barista · GT agent workshop</title>
<style>
:root{--ink:#1D1D1F;--ink2:#6E6E73;--ink3:#A1A1A6;--line:#D9D6E0;--gt:#4F2D7F;--tint:#F6F3FA;--ok:#1E7B4A;--bad:#B42318;--bg:#fff}
*{box-sizing:border-box}
html{scroll-behavior:smooth;scroll-padding-top:64px}
body{margin:0;background:var(--bg);color:var(--ink);font:17px/1.55 -apple-system,BlinkMacSystemFont,"Helvetica Neue","Segoe UI",Arial,sans-serif;-webkit-font-smoothing:antialiased}
p,h1,h2,h3,h4,ul,pre,figure{margin:0}
.wrap{max-width:1040px;margin:0 auto;padding-left:max(24px,env(safe-area-inset-left,0px));padding-right:max(24px,env(safe-area-inset-right,0px))}
nav.top{position:sticky;top:0;z-index:5;background:rgba(255,255,255,.92);backdrop-filter:saturate(180%) blur(16px);-webkit-backdrop-filter:saturate(180%) blur(16px);border-bottom:1px solid var(--line)}
nav.top .wrap{display:flex;align-items:center;gap:24px;height:56px}
nav.top img{height:22px;width:auto}
nav.top .steps{display:flex;gap:2px;margin-left:auto;overflow-x:auto;scrollbar-width:none;min-width:0}
nav.top .steps a{font-size:13px;color:var(--ink2);text-decoration:none;width:28px;height:28px;display:grid;place-items:center;border-radius:14px;flex:none}
nav.top .steps a.w{width:auto;padding-inline:10px}
nav.top .steps a:hover{background:var(--tint);color:var(--gt)}
.eb,.k{font-size:12px;letter-spacing:.08em;text-transform:uppercase;color:var(--gt);font-weight:600}
.hero{padding-block:96px 72px;border-bottom:1px solid var(--line)}
.hero h1{font-size:clamp(48px,9vw,96px);line-height:1.02;letter-spacing:-.035em;font-weight:600;margin-top:16px;text-wrap:balance}
.hero .sub{font-size:clamp(19px,2.4vw,24px);color:var(--ink2);max-width:640px;margin-top:20px;line-height:1.4}
.icons{display:flex;align-items:center;margin-top:56px;max-width:560px}
.icons img{flex:none;width:clamp(40px,8vw,56px);height:auto}
.icons i{flex:1;height:1px;background:var(--line);margin-inline:12px}
.start{display:grid;grid-template-columns:repeat(3,minmax(0,1fr));gap:40px;padding-block:64px;border-bottom:1px solid var(--line)}
.start>div{border-top:1px solid var(--gt);padding-top:16px;min-width:0}
.start h3{font-size:20px;font-weight:600;margin:8px 0 6px;letter-spacing:-.01em}
.start p{color:var(--ink2);font-size:16px}
.term{background:#1D1D1F;color:#E8E6EC;border-radius:10px;padding:20px 24px;font:14px/1.6 Menlo,Consolas,monospace;margin-top:12px;overflow-x:auto}
.term b{color:#B9A3DA;font-weight:400}
.xp{padding-block:72px;border-bottom:1px solid var(--line)}
.xp h2,.act h2,.trouble h2{font-size:clamp(36px,6vw,56px);letter-spacing:-.03em;line-height:1.05;font-weight:600;margin-top:12px}
.xp>p{color:var(--ink2);max-width:640px;margin-top:16px;font-size:19px}
.xp .grid{display:grid;grid-template-columns:minmax(0,1fr) minmax(0,1fr);gap:48px;margin-top:40px}
table{width:100%;border-collapse:collapse;font-size:15px}
td{padding:9px 0;border-bottom:1px solid var(--line);vertical-align:top}
td:last-child{text-align:right;color:var(--gt);font-variant-numeric:tabular-nums;white-space:nowrap;padding-left:16px}
.badges td:first-child{white-space:nowrap;padding-right:16px;font-weight:600}
.badges td:last-child{text-align:left;color:var(--ink2);white-space:normal}
svg{width:100%;height:auto;display:block;overflow:visible}
svg .rail{stroke:var(--line);stroke-width:1.5}
svg .seg{stroke:var(--gt);stroke-width:2}
svg .dash{stroke-dasharray:4 5}
svg .tick{stroke:var(--gt);stroke-width:1.5}
svg .lab{font:600 14px -apple-system,"Helvetica Neue","Segoe UI",Arial,sans-serif;fill:var(--ink);text-anchor:middle}
svg .sub{font:12.5px -apple-system,"Helvetica Neue","Segoe UI",Arial,sans-serif;fill:var(--ink2);text-anchor:middle}
svg .l{text-anchor:start} svg .e{text-anchor:end}
.dia{margin-top:48px;overflow-x:auto}
.dia svg{min-width:640px}
.dia figcaption,.shot figcaption{font-size:14px;color:var(--ink2);margin-top:14px}
.act{padding-block:112px 40px}
.act>p{font-size:21px;color:var(--ink2);max-width:640px;margin-top:16px;line-height:1.45}
.step{display:grid;grid-template-columns:96px minmax(0,1fr);gap:24px;padding-block:48px;border-top:1px solid var(--line)}
.num{font-size:40px;font-weight:300;color:var(--gt);letter-spacing:-.02em;font-variant-numeric:tabular-nums;line-height:1}
.step h3{font-size:30px;font-weight:600;letter-spacing:-.02em;line-height:1.15}
.do{margin-top:24px;padding:20px 24px;background:var(--tint);border-radius:12px}
.do ul{margin-top:8px}
.step ul{padding:0;list-style:none}
.step li{position:relative;padding-left:22px;margin-top:6px}
.step li::before{content:"→";position:absolute;left:0;color:var(--gt)}
.cols{display:grid;grid-template-columns:minmax(0,1fr) minmax(0,1fr);gap:40px;margin-top:28px}
.cols>div{border-top:1px solid var(--line);padding-top:14px;min-width:0}
.cols p,.cols li{font-size:16px;color:#3A3A3C}
.k+p,.k+ul{margin-top:8px}
p+p,p+ul,ul+p,pre+p,p+pre,ul+pre{margin-top:12px}
pre{font:13.5px/1.55 Menlo,Consolas,monospace;color:var(--ink);overflow-x:auto;padding:4px 0;white-space:pre}
code{font:.88em Menlo,Consolas,monospace;background:var(--tint);padding:1px 5px;border-radius:4px}
.shot{margin-top:32px}
.shot img{width:100%;max-width:760px;border:1px solid var(--line);border-radius:10px}
.quiz{margin-top:32px;border-top:1px solid var(--gt);padding-top:14px}
.quiz .q{font-weight:600;margin-top:8px}
.opts{display:grid;gap:8px;margin-top:12px;max-width:620px}
.opts button{all:unset;cursor:pointer;display:flex;gap:12px;align-items:baseline;padding:10px 14px;border:1px solid var(--line);border-radius:10px;font-size:16px;transition:border-color .2s,background .2s}
.opts button span{color:var(--gt);font-weight:600}
.opts button:hover{border-color:var(--gt)}
.opts button:focus-visible{outline:2px solid var(--gt);outline-offset:2px}
.opts button.ok{border-color:var(--ok);background:#EEF7F1}
.opts button.no{border-color:var(--bad);background:#FDF1F0}
.because{margin-top:12px;color:var(--ink2);font-size:16px}
details{margin-top:24px;border-top:1px solid var(--line);padding-top:12px}
summary{cursor:pointer;color:var(--gt);font-weight:600;font-size:15px}
details[open] summary{margin-bottom:10px}
details p,details pre{font-size:15px}
.trouble{padding-block:112px 64px;border-top:1px solid var(--line)}
table.md{margin-top:12px;max-width:760px}
table.md th{text-align:left;font-size:12px;letter-spacing:.06em;text-transform:uppercase;color:var(--gt);font-weight:600;padding:8px 16px 8px 0;border-bottom:1px solid var(--gt)}
table.md td{padding:9px 16px 9px 0}
table.md td:last-child{text-align:left;color:#3A3A3C;white-space:normal;padding-left:0}
.trouble ol{padding-left:22px;color:#3A3A3C;font-size:16px;margin-top:6px;max-width:760px}
.trouble ol li+li,.trouble ul li+li{margin-top:4px}
.trouble a{color:var(--gt)}
.gitbash{border-top:0;padding-top:72px;border-bottom:1px solid var(--line)}
.trouble h3{font-size:22px;margin-top:48px;letter-spacing:-.01em}
.trouble h4{font-size:17px;margin-top:28px}
.trouble p,.trouble ul{color:#3A3A3C;font-size:16px;margin-top:6px;max-width:760px}
.trouble ul{padding-left:20px}
.trouble pre{margin-top:8px;background:var(--tint);border-radius:8px;padding:12px 16px}
footer{border-top:1px solid var(--line);padding-block:40px 64px;display:flex;justify-content:space-between;align-items:center;gap:24px;flex-wrap:wrap;color:var(--ink2);font-size:15px}
footer img{height:26px;width:auto}
@media (max-width:760px){
  .start,.xp .grid,.cols{grid-template-columns:minmax(0,1fr);gap:28px}
  .step{grid-template-columns:minmax(0,1fr);gap:8px}
  .num{font-size:28px}
  .hero{padding-block:64px 48px}
  nav.top .steps{display:none}
}
@media (prefers-reduced-motion:no-preference){
  .grow{stroke-dasharray:800;stroke-dashoffset:800;animation:grow 2.4s cubic-bezier(.2,.7,.2,1) .3s forwards}
  @keyframes grow{to{stroke-dashoffset:0}}
}
</style>
</head>
<body>
<nav class="top"><div class="wrap"><img src="img/logo.png" alt="Grant Thornton"><div class="steps"><a class="w" href="#git-bash">Setup</a>__NAV__<a class="w" href="#troubleshooting">Help</a></div></div></nav>
<main class="wrap">
  <section class="hero">
    <div class="eb">GT agent workshop · for builders</div>
    <h1>Build a barista.</h1>
    <p class="sub">From an empty folder to a working Copilot Studio agent in 15 steps. A Git Bash wizard walks you through it one screen at a time, and code checks the numbers your flow and agent give back.</p>
    <div class="icons">__ICONS__</div>
  </section>

  <section class="start">
    <div><div class="k">1 · Unzip</div><h3>Extract the folder</h3><p>Right-click the zip, <b>Extract All</b>. Running it from inside the zip doesn't work. Never used Git Bash? <a href="#git-bash">Start with Git Bash from zero</a>.</p></div>
    <div><div class="k">2 · Open</div><h3>Double-click start.cmd</h3><p>It finds Git Bash and opens the wizard at the right size. Or right-click the folder, <b>Open Git Bash here</b>.</p></div>
    <div><div class="k">3 · Play</div><h3>Follow the screens</h3>
      <div class="term">$ <b>bash start.sh</b><br>$ <b>bash start.sh doctor</b></div><p style="margin-top:8px">The second one checks your laptop when something's off.</p></div>
  </section>

  <section class="trouble gitbash" id="git-bash">
    <div class="eb">Before you start</div>
    <h2>Git Bash from zero.</h2>
__GITBASH__
  </section>

  <section class="xp">
    <div class="eb">The XP system</div>
    <h2>Read, build, prove it.</h2>
    <p>Every step pays XP. Reading why it works pays too, and the quizzes ask about what you read. Code checks three numbers along the way, and those pay the most.</p>
    <figure class="dia">__LADDER__</figure>
    <div class="grid">
      <div><div class="k">How you earn XP</div>
        <table>
          <tr><td>Finish a step</td><td>+100</td></tr>
          <tr><td>Open a step's Why (w) or Inside (i) screen</td><td>+10 each</td></tr>
          <tr><td>Quiz right the first time / second time</td><td>+50 / +20</td></tr>
          <tr><td>Streak: quizzes right first time in a row</td><td>+10 per streak, max +50</td></tr>
          <tr><td>Check: flow rows (step 7), agent answer (13)</td><td>+100 each</td></tr>
          <tr><td>Final check: the agent after your new row (15)</td><td>+250</td></tr>
          <tr><td>Every badge</td><td>+50</td></tr>
        </table>
      </div>
      <div><div class="k">Eight badges</div>
        <table class="badges">
          <tr><td>Data drop</td><td>Your data sits in a named table in the cloud</td></tr>
          <tr><td>Deterministic</td><td>Your flow counted, the same way twice</td></tr>
          <tr><td>Agent born</td><td>Your agent has a tool it can call</td></tr>
          <tr><td>Live data</td><td>The data changed, the agent kept up, code agreed</td></tr>
          <tr><td>Quiz master</td><td>Every quiz right the first time</td></tr>
          <tr><td>Curious</td><td>Read every Why and every Inside screen</td></tr>
          <tr><td>Speedrun</td><td>Finished within 40 minutes</td></tr>
          <tr><td>Partner</td><td>Reached the top of the ladder</td></tr>
        </table>
      </div>
    </div>
  </section>

__STEPS__

  <section class="trouble" id="troubleshooting">
    <div class="eb">When something's off</div>
    <h2>Troubleshooting.</h2>
__TROUBLE__
  </section>

  <footer><img src="img/logo.png" alt="Grant Thornton"><span>Code calculates. The LLM explains. Code checks.</span></footer>
</main>
<script>
document.querySelectorAll('.quiz').forEach(q => {
  q.querySelectorAll('button').forEach(b => b.addEventListener('click', () => {
    b.classList.add(b.dataset.ok === '1' ? 'ok' : 'no');
    if (b.dataset.ok === '1') q.querySelector('.because').hidden = false;
  }));
});
</script>
</body>
</html>
"""

if __name__ == "__main__":
    main()
