from pathlib import Path
from reportlab.lib import colors
from reportlab.lib.enums import TA_LEFT
from reportlab.lib.pagesizes import letter
from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
from reportlab.lib.units import inch
from reportlab.platypus import Image, PageBreak, Paragraph, SimpleDocTemplate, Spacer, Table, TableStyle
from PIL import Image as PILImage

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / "docs" / "ClipStack-Setup-Guide.pdf"
PURPLE = colors.HexColor("#8663e9")
INK = colors.HexColor("#191827")
MUTED = colors.HexColor("#696779")
PALE = colors.HexColor("#f4f0ff")
LINE = colors.HexColor("#e7e3ef")
styles = getSampleStyleSheet()
styles.add(ParagraphStyle(name="CoverTitle", parent=styles["Title"], fontName="Helvetica-Bold", fontSize=30, leading=35, textColor=INK, alignment=TA_LEFT, spaceAfter=8))
styles.add(ParagraphStyle(name="SubTitle", parent=styles["Normal"], fontName="Helvetica", fontSize=13, leading=19, textColor=MUTED, spaceAfter=13))
styles.add(ParagraphStyle(name="Section", parent=styles["Heading1"], fontName="Helvetica-Bold", fontSize=18, leading=23, textColor=INK, spaceBefore=2, spaceAfter=9))
styles.add(ParagraphStyle(name="SubSection", parent=styles["Heading2"], fontName="Helvetica-Bold", fontSize=11, leading=14, textColor=PURPLE, spaceBefore=7, spaceAfter=4))
styles.add(ParagraphStyle(name="Body", parent=styles["BodyText"], fontName="Helvetica", fontSize=9.2, leading=13.2, textColor=INK, spaceAfter=5))
styles.add(ParagraphStyle(name="Small", parent=styles["BodyText"], fontName="Helvetica", fontSize=8, leading=11, textColor=MUTED, spaceAfter=4))
styles.add(ParagraphStyle(name="Step", parent=styles["BodyText"], fontName="Helvetica", fontSize=9.2, leading=13.4, textColor=INK, leftIndent=18, firstLineIndent=-18, spaceAfter=6))
styles.add(ParagraphStyle(name="Callout", parent=styles["BodyText"], fontName="Helvetica-Bold", fontSize=9, leading=13, textColor=INK, backColor=PALE, borderColor=PALE, borderWidth=1, borderPadding=8, spaceBefore=5, spaceAfter=8))
styles.add(ParagraphStyle(name="TableHead", parent=styles["BodyText"], fontName="Helvetica-Bold", fontSize=8.3, leading=11, textColor=colors.white))
styles.add(ParagraphStyle(name="TableCell", parent=styles["BodyText"], fontName="Helvetica", fontSize=8.2, leading=11.3, textColor=INK))

def p(text, style="Body"):
    return Paragraph(text, styles[style])

def step(number, title, detail):
    return p(f"<font color='#8663e9'><b>{number}.</b></font> <b>{title}</b> {detail}", "Step")

def screenshot(name, width=3.5 * inch):
    image_path = ROOT / "docs" / name
    with PILImage.open(image_path) as source:
        ratio = source.height / source.width
    image = Image(str(image_path), width=width, height=width * ratio)
    image.hAlign = "CENTER"
    return image

def make_table(rows, widths):
    table = Table(rows, colWidths=widths, repeatRows=1, hAlign="LEFT")
    table.setStyle(TableStyle([("BACKGROUND", (0, 0), (-1, 0), PURPLE), ("GRID", (0, 0), (-1, -1), 0.5, LINE), ("VALIGN", (0, 0), (-1, -1), "TOP"), ("LEFTPADDING", (0, 0), (-1, -1), 8), ("RIGHTPADDING", (0, 0), (-1, -1), 8), ("TOPPADDING", (0, 0), (-1, -1), 7), ("BOTTOMPADDING", (0, 0), (-1, -1), 7)]))
    return table

def footer(canvas, doc):
    canvas.saveState()
    w, _ = letter
    canvas.setStrokeColor(LINE)
    canvas.line(.62 * inch, .52 * inch, w - .62 * inch, .52 * inch)
    canvas.setFont("Helvetica", 7.5)
    canvas.setFillColor(MUTED)
    canvas.drawString(.62 * inch, .34 * inch, "CLIPSTACK  ·  SETUP AND USE GUIDE")
    canvas.drawRightString(w - .62 * inch, .34 * inch, str(doc.page))
    canvas.restoreState()

doc = SimpleDocTemplate(str(OUT), pagesize=letter, rightMargin=.68 * inch, leftMargin=.68 * inch, topMargin=.62 * inch, bottomMargin=.72 * inch, title="ClipStack Setup and Use Guide", author="ClipStack")
story = []

# 1. Install
story += [p("CLIPSTACK  /  DESKTOP GUIDE", "SubSection"), p("Your clipboard,<br/>remembered.", "CoverTitle"), p("Setup and use guide for Windows and macOS", "SubTitle")]
story += [p("ClipStack keeps a searchable history of text and images you copy. Your history stays on your device. Select an item to copy it back, then use the normal Paste shortcut in your app.")]
story += [p("1  Install the app", "Section"), p("Windows 10 / 11", "SubSection")]
story += [step("1", "Download", "<link href='https://github.com/Digimo2020/ClipStack/releases/latest/download/ClipStack-Setup.exe' color='#704bcc'>ClipStack-Setup.exe</link> from the <link href='https://github.com/Digimo2020/ClipStack/releases/latest' color='#704bcc'>latest public release</link>."), step("2", "Run the installer.", "It installs for your Windows account and does not need administrator access. Choose an install folder if you want to change the default."), step("3", "If SmartScreen warns you", "review the prompt. This app is unsigned, so Windows may ask you to confirm before opening it."), step("4", "Start ClipStack", "from the Start menu. Find its icon by the clock; open the hidden-icons arrow if needed.")]
story += [p("macOS 14+ (Apple Silicon)", "SubSection"), step("1", "Download", "<link href='https://github.com/Digimo2020/ClipStack/releases/latest/download/ClipStack.dmg' color='#704bcc'>ClipStack.dmg</link> from the latest release."), step("2", "Open the DMG", "and drag ClipStack into Applications."), step("3", "First launch", "macOS may say Apple cannot verify the app because it is not notarized. Use System Settings &gt; Privacy &amp; Security &gt; Open Anyway, then launch ClipStack again."), p("Clipboard history is stored locally. ClipStack does not upload clipboard contents.", "Callout"), PageBreak()]

# 2. History panel
story += [p("2  Find and paste a copy", "Section"), p("Open the history panel with your shortcut. Search for a word or use the tabs to narrow the list. Click an item to copy it; switch back to your destination app and paste as usual."), screenshot("windows-history.png", 3.5 * inch), p("Windows interface preview with sample content.", "Small"), p("What the controls do", "SubSection")]
story += [make_table([[p("Control", "TableHead"), p("Action", "TableHead")], [p("Search", "TableCell"), p("Filter copied text as you type.", "TableCell")], [p("All / Text / Images / Links / Pinned", "TableCell"), p("Show all items or a matching type; Pinned shows saved favourites.", "TableCell")], [p("Select an item", "TableCell"), p("Copy it to the system clipboard. Paste in the destination app.", "TableCell")], [p("Star", "TableCell"), p("Pin or unpin an item. Pins remain when unpinned items are removed.", "TableCell")], [p("Trash", "TableCell"), p("Delete one item from history.", "TableCell")]], [2.15 * inch, 4.45 * inch]), Spacer(1, 8), p("Copied images appear with a thumbnail. If you copy the same item again, it moves to the top of the list."), PageBreak()]

# 3. Settings and shortcuts
story += [p("3  Set your shortcut and history", "Section"), p("Open Settings from the gear icon in the history window. Windows and Mac have different system shortcuts, so choose a preset that suits your computer."), screenshot("windows-settings.png", 3.25 * inch), p("Windows settings preview with sample values.", "Small"), p("Windows shortcut options", "SubSection")]
story += [make_table([[p("Shortcut", "TableHead"), p("When to use it", "TableHead")], [p("Ctrl + Shift + V", "TableCell"), p("Default. Opens ClipStack history.", "TableCell")], [p("Ctrl + Alt + V", "TableCell"), p("Choose if another app uses the default.", "TableCell")], [p("Alt + V", "TableCell"), p("Alternative when the other combinations conflict.", "TableCell")]], [2.15 * inch, 4.45 * inch]), Spacer(1, 5), p("Windows reserves Win + V for its own clipboard history. ClipStack leaves Win + V and Ctrl + V available.", "Callout"), p("macOS shortcut options", "SubSection"), p("ClipStack for Mac starts with <b>Command + Shift + V</b>. Settings offer <b>Command + Option + V</b>, <b>Control + Shift + V</b>, <b>Control + Option + V</b> and <b>Option + V</b>. Command + V remains the system Paste shortcut."), PageBreak()]

# 4. Privacy and troubleshooting
story += [p("4  Keep history the way you want", "Section"), p("In Settings, change the history size from 20 to 200 unpinned items. Pinned items are kept separately. Pause capturing when you do not want new copies saved, or choose Clear unpinned items to clear the list while keeping pins."), p("Launch at sign-in", "SubSection"), p("Turn on Launch at sign-in in Windows settings to start ClipStack when you sign in. The app stays in the notification area, ready for the shortcut."), p("Privacy and storage", "SubSection"), p("Windows history is stored under <b>%APPDATA%\\ClipStack\\</b> as a JSON history file and separate image files. Mac history is stored under <b>~/Library/Application Support/ClipStack/</b>. Nothing is uploaded. Windows clipboard entries marked to be excluded from monitoring are skipped when Windows exposes that marker."), p("Troubleshooting", "SubSection"), p("<b>The shortcut does nothing:</b> another app may own that key combination. Open Settings from the tray and select another shortcut. On Windows, the default is Ctrl + Shift + V; on Mac, Command + Shift + V."), p("<b>ClipStack copies but does not paste automatically:</b> this is expected. Click an item to copy it, then press Ctrl + V on Windows or Command + V on Mac in the destination app."), p("<b>I cannot see the Windows tray icon:</b> open the hidden-icons arrow beside the clock. ClipStack also appears in the Start menu."), p("<b>macOS will not open the app:</b> use System Settings &gt; Privacy &amp; Security &gt; Open Anyway once, then open ClipStack again."), Spacer(1, 8), p("Get the latest installers and source at <link href='https://github.com/Digimo2020/ClipStack/releases/latest' color='#704bcc'>github.com/Digimo2020/ClipStack</link>.", "Callout")]

doc.build(story, onFirstPage=footer, onLaterPages=footer)
print(OUT)
