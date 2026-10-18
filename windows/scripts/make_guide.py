"""Build the illustrated, platform-specific ClipStack setup guide."""
from pathlib import Path
from io import BytesIO

from PIL import Image as PILImage
from reportlab.lib import colors
from reportlab.lib.enums import TA_CENTER, TA_LEFT
from reportlab.lib.pagesizes import letter
from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
from reportlab.lib.units import inch
from reportlab.pdfbase.pdfmetrics import stringWidth
from reportlab.platypus import (Flowable, Image, PageBreak, Paragraph,
                                SimpleDocTemplate, Spacer, Table, TableStyle)

ROOT = Path(__file__).resolve().parents[2]
DOCS = ROOT / "docs"
OUT = DOCS / "ClipStack-Setup-Guide.pdf"
PURPLE = colors.HexColor("#7048E8")
VIOLET = colors.HexColor("#9C65F5")
INK = colors.HexColor("#17142B")
MUTED = colors.HexColor("#66647A")
PALE = colors.HexColor("#F3EFFF")
PALE_BLUE = colors.HexColor("#EDF4FF")
LINE = colors.HexColor("#E6E2EE")
WHITE = colors.white

styles = getSampleStyleSheet()
styles.add(ParagraphStyle(name="Eyebrow", fontName="Helvetica-Bold", fontSize=8,
                          leading=10, textColor=PURPLE, spaceAfter=7, tracking=1.1))
styles.add(ParagraphStyle(name="CoverTitle", fontName="Helvetica-Bold", fontSize=32,
                          leading=36, textColor=INK, spaceAfter=9))
styles.add(ParagraphStyle(name="CoverSub", fontName="Helvetica", fontSize=12,
                          leading=18, textColor=MUTED, spaceAfter=12))
styles.add(ParagraphStyle(name="Section", fontName="Helvetica-Bold", fontSize=21,
                          leading=25, textColor=INK, spaceAfter=7))
styles.add(ParagraphStyle(name="Sub", fontName="Helvetica-Bold", fontSize=11,
                          leading=14, textColor=PURPLE, spaceBefore=7, spaceAfter=4))
styles.add(ParagraphStyle(name="Body", fontName="Helvetica", fontSize=9.1,
                          leading=13.2, textColor=INK, spaceAfter=6))
styles.add(ParagraphStyle(name="Small", fontName="Helvetica", fontSize=7.8,
                          leading=10, textColor=MUTED, spaceAfter=5))
styles.add(ParagraphStyle(name="Step", fontName="Helvetica", fontSize=9,
                          leading=13, textColor=INK, leftIndent=20,
                          firstLineIndent=-20, spaceAfter=7))
styles.add(ParagraphStyle(name="Callout", fontName="Helvetica", fontSize=8.7,
                          leading=12.5, textColor=INK, backColor=PALE,
                          borderColor=PALE, borderWidth=1, borderPadding=8,
                          spaceBefore=5, spaceAfter=8))
styles.add(ParagraphStyle(name="TableHead", fontName="Helvetica-Bold", fontSize=8,
                          leading=10, textColor=WHITE))
styles.add(ParagraphStyle(name="TableCell", fontName="Helvetica", fontSize=8,
                          leading=10.5, textColor=INK))
styles.add(ParagraphStyle(name="TOC", fontName="Helvetica-Bold", fontSize=11,
                          leading=15, textColor=INK, spaceAfter=2))
styles.add(ParagraphStyle(name="CardHead", fontName="Helvetica-Bold", fontSize=13,
                          leading=16, textColor=INK, spaceAfter=5))


def p(text, style="Body"):
    return Paragraph(text, styles[style])


def step(number, title, detail):
    return p(f"<font color='#7048E8'><b>{number:02d}</b></font>  <b>{title}</b> {detail}", "Step")


def screenshot(name, width, caption):
    path = DOCS / name
    with PILImage.open(path) as src:
        ratio = src.height / src.width
        preview = src.convert("RGB")
        preview.thumbnail((1600, 1600), PILImage.Resampling.LANCZOS)
        compressed = BytesIO()
        preview.save(compressed, format="JPEG", quality=86, optimize=True)
        compressed.seek(0)
    img = Image(compressed, width=width, height=width * ratio)
    img.hAlign = "CENTER"
    return [img, p(caption, "Small")]


def table(rows, widths, header=True, bg=PURPLE):
    t = Table(rows, colWidths=widths, repeatRows=1 if header else 0, hAlign="LEFT")
    cmds = [
        ("GRID", (0, 0), (-1, -1), .45, LINE),
        ("VALIGN", (0, 0), (-1, -1), "TOP"),
        ("LEFTPADDING", (0, 0), (-1, -1), 8),
        ("RIGHTPADDING", (0, 0), (-1, -1), 8),
        ("TOPPADDING", (0, 0), (-1, -1), 6),
        ("BOTTOMPADDING", (0, 0), (-1, -1), 6),
    ]
    if header:
        cmds += [("BACKGROUND", (0, 0), (-1, 0), bg),
                 ("ROWBACKGROUNDS", (0, 1), (-1, -1), [WHITE, colors.HexColor("#FAF9FC")])]
    t.setStyle(TableStyle(cmds))
    return t


class Bookmark(Flowable):
    def __init__(self, key, title, level=0):
        super().__init__()
        self.key, self.title, self.level = key, title, level
        self.width, self.height = 0, 0

    def draw(self):
        self.canv.bookmarkPage(self.key)
        self.canv.addOutlineEntry(self.title, self.key, self.level, False)


def section_header(label, title, subtitle):
    return [p(label.upper(), "Eyebrow"), p(title, "Section"), p(subtitle, "Body"),
            Spacer(1, 3)]


def footer(canvas, doc):
    canvas.saveState()
    w, h = letter
    if doc.page == 1:
        canvas.setFillColor(PURPLE)
        canvas.rect(0, h - 9, w, 9, stroke=0, fill=1)
    else:
        canvas.setStrokeColor(LINE)
        canvas.setLineWidth(.6)
        canvas.line(.62 * inch, .52 * inch, w - .62 * inch, .52 * inch)
        canvas.setFont("Helvetica-Bold", 7)
        canvas.setFillColor(PURPLE)
        canvas.drawString(.62 * inch, .34 * inch, "CLIPSTACK  /  SETUP GUIDE")
        canvas.setFont("Helvetica", 7.5)
        canvas.setFillColor(MUTED)
        canvas.drawRightString(w - .62 * inch, .34 * inch, f"{doc.page:02d}")
    canvas.restoreState()


doc = SimpleDocTemplate(str(OUT), pagesize=letter, rightMargin=.66 * inch,
                        leftMargin=.66 * inch, topMargin=.58 * inch,
                        bottomMargin=.72 * inch, title="ClipStack Setup Guide",
                        author="ClipStack")
story = []

# Cover and platform jump points. PDF outlines are also added for the sidebar.
story += [Spacer(1, .20 * inch), p("CLIPSTACK  /  DESKTOP APP", "Eyebrow"),
          p("Your clipboard,<br/>remembered.", "CoverTitle"),
          p("A visual setup and quick-start guide for macOS and Windows.", "CoverSub")]
hero = DOCS / "ClipStack Clipboard History Dashboard-1.png"
if hero.exists():
    story += screenshot(hero.name, 6.95 * inch,
                        "ClipStack clipboard history · product artwork")
story += [Spacer(1, 5), p("Choose your computer", "Sub")]
mac_card = [p("01  /  MAC", "Eyebrow"),
            p("Start with macOS", "CardHead"),
            p("Install the DMG, grant optional paste access, and learn the Mac shortcuts.", "Small"),
            p("<link href='#mac-start' color='#7048E8'>OPEN MAC GUIDE  →</link>", "Small")]
win_card = [p("02  /  WINDOWS", "Eyebrow"),
            p("Start with Windows", "CardHead"),
            p("Install the EXE, open the history window, and choose a shortcut.", "Small"),
            p("<link href='#windows-start' color='#7048E8'>OPEN WINDOWS GUIDE  →</link>", "Small")]
cards = Table([[mac_card, win_card]], colWidths=[3.43 * inch, 3.43 * inch])
cards.setStyle(TableStyle([
    ("BACKGROUND", (0, 0), (0, 0), PALE), ("BACKGROUND", (1, 0), (1, 0), PALE_BLUE),
    ("BOX", (0, 0), (0, 0), .5, colors.HexColor("#DDD2FF")),
    ("BOX", (1, 0), (1, 0), .5, colors.HexColor("#D7E5FA")),
    ("VALIGN", (0, 0), (-1, -1), "TOP"), ("LEFTPADDING", (0, 0), (-1, -1), 13),
    ("RIGHTPADDING", (0, 0), (-1, -1), 13), ("TOPPADDING", (0, 0), (-1, -1), 12),
    ("BOTTOMPADDING", (0, 0), (-1, -1), 10), ("LINEBEFORE", (1, 0), (1, 0), 8, WHITE),
]))
story += [cards, Spacer(1, 9),
          p("ClipStack keeps a searchable history of copied text and images on your device. Select an item to copy it again, then paste normally in your app.", "Body"),
          p("Choose a section above or use the PDF outline/bookmarks panel to jump directly to Mac or Windows.", "Callout"), PageBreak()]

# Mac guide, intentionally first and kept self-contained.
story += [Bookmark("mac-start", "Mac guide"),
          *section_header("01  /  macOS 14+ · Apple Silicon", "Set up ClipStack on Mac",
                          "Download the DMG, move the app to Applications, then open your history with the Mac shortcut.")]
story += [p("Install", "Sub")]
story += [step(1, "Download the Mac build.", f"Get <link href='https://github.com/Digimo2020/ClipStack/releases/latest/download/ClipStack.dmg' color='#7048E8'>ClipStack.dmg</link> from the latest public release."),
          step(2, "Install the app.", "Open the DMG and drag ClipStack onto the Applications folder."),
          step(3, "Open ClipStack.", "On first launch, macOS may block this unsigned app. In System Settings → Privacy &amp; Security, choose Open Anyway, then launch ClipStack again."),
          step(4, "Allow automatic paste (optional).", "When prompted, enable ClipStack under System Settings → Privacy &amp; Security → Accessibility. Without it, selecting an item copies it and you paste with ⌘V yourself."),
          p("Mac app preview", "Sub")]
story += screenshot("a5324fbe-cc95-42cd-959f-21f3cd908600.png", 5.0 * inch,
                    "Illustrative Mac product preview; controls and sample clipboard entries are shown for orientation.")
story += [PageBreak(), Bookmark("mac-use", "Mac use and shortcuts", 1),
          *section_header("MAC  /  USE", "Find a copy and paste it",
                          "Open the floating history panel, search or filter, select a result, then paste in the destination app.")]
mac_flow = Table([[p("COPY", "TOC"), p("→", "TOC"), p("SEARCH", "TOC"), p("→", "TOC"),
                   p("SELECT", "TOC"), p("→", "TOC"), p("⌘V", "TOC")]],
                 colWidths=[.95*inch, .25*inch, 1.2*inch, .25*inch, 1.15*inch, .25*inch, 1*inch])
mac_flow.setStyle(TableStyle([("BACKGROUND", (0,0), (-1,-1), PALE),
                              ("ALIGN", (0,0), (-1,-1), "CENTER"),
                              ("TOPPADDING", (0,0), (-1,-1), 9),
                              ("BOTTOMPADDING", (0,0), (-1,-1), 9)]))
story += [mac_flow, Spacer(1, 7), p("Keyboard shortcuts", "Sub")]
story += [table([[p("Shortcut", "TableHead"), p("Action", "TableHead")],
                 [p("⌘ + ⇧ + V", "TableCell"), p("Open history (default).", "TableCell")],
                 [p("⌘ + ⌥ + V · ⌃ + ⇧ + V · ⌃ + ⌥ + V · ⌥ + V", "TableCell"),
                  p("Alternative history shortcuts in Settings.", "TableCell")],
                 [p("⌘ + V", "TableCell"), p("Paste the selected item in the destination app.", "TableCell")]],
                 [3.0*inch, 3.75*inch]), Spacer(1, 7),
          p("The panel can also filter by item type and pin favourites. Pinned items are retained separately when you clear unpinned history.", "Body"),
          p("Mac privacy &amp; help", "Sub"),
          p("History stays on this Mac in ~/Library/Application Support/ClipStack/. ClipStack does not upload clipboard content. If the shortcut is already used by another app, choose a different preset in Settings. For the latest Mac installer, use the <link href='https://github.com/Digimo2020/ClipStack/releases/latest' color='#7048E8'>public release page</link>.", "Callout"), PageBreak()]

# Windows section begins after Mac pages with its own direct destination.
story += [Bookmark("windows-start", "Windows guide"),
          *section_header("02  /  WINDOWS 10–11 · 64-BIT", "Set up ClipStack on Windows",
                          "Install for your Windows account, launch from Start, and open the history panel with your shortcut.")]
story += [p("Install", "Sub"),
          step(1, "Download the Windows installer.", "Get <link href='https://github.com/Digimo2020/ClipStack/releases/latest/download/ClipStack-Setup.exe' color='#7048E8'>ClipStack-Setup.exe</link> from the latest public release."),
          step(2, "Run the installer.", "It installs for your account without administrator access. Choose another folder in the installer if you prefer."),
          step(3, "Confirm the first-run prompt.", "The app is unsigned; Windows SmartScreen may ask you to review and confirm before opening it."),
          step(4, "Start ClipStack.", "Open it from the Start menu. The app stays in the notification area by the clock; check the hidden-icons arrow if you do not see it."),
          p("Open history", "Sub"),
          p("Press <b>Ctrl + Shift + V</b> to show the panel. Search or choose a content tab, select an item to copy it, then press <b>Ctrl + V</b> in the destination app.", "Body")]
story += screenshot("windows-history.png", 3.15 * inch,
                    "Windows history window · genuine app screenshot with sample content.")
story += [Spacer(1, 3), p("Inside the history window", "Sub"),
          table([[p("Control", "TableHead"), p("What it does", "TableHead")],
                 [p("Search and type filters", "TableCell"), p("Narrow the history by phrase or content type.", "TableCell")],
                 [p("Select an item", "TableCell"), p("Copy it; paste with Ctrl + V in another app.", "TableCell")],
                 [p("Pin / delete", "TableCell"), p("Keep favourites or remove an entry.", "TableCell")]],
                 [2.2*inch, 4.55*inch]), PageBreak()]

story += [Bookmark("windows-settings", "Windows settings and shortcuts", 1),
          *section_header("WINDOWS  /  PERSONALIZE", "Pick your shortcut and preferences",
                          "Open Settings from the gear icon in the history panel. Changes are stored locally.")]
story += screenshot("windows-settings.png", 3.15 * inch,
                    "Windows Settings window · genuine app screenshot with sample values.")
story += [p("Available history shortcuts", "Sub"),
          table([[p("Shortcut", "TableHead"), p("Use", "TableHead")],
                 [p("Ctrl + Shift + V", "TableCell"), p("Default shortcut.", "TableCell")],
                 [p("Ctrl + Alt + V", "TableCell"), p("Alternative if another app uses the default.", "TableCell")],
                 [p("Alt + V", "TableCell"), p("Another available alternative.", "TableCell")],
                 [p("Ctrl + V", "TableCell"), p("Paste in the active app; ClipStack leaves it available.", "TableCell")]],
                 [2.1*inch, 4.65*inch]), Spacer(1, 5),
          p("Windows keeps Win + V for its own clipboard history. ClipStack uses a separate shortcut.", "Callout"),
          p("Useful settings", "Sub"),
          p("Set the unpinned history limit (20–200), pause capture, clear unpinned items, or enable Launch at sign-in. ClipStack stays in the notification area when its window is closed.", "Body"),
          p("Windows storage &amp; troubleshooting", "Sub"),
          p("History is stored in %APPDATA%\\ClipStack\\ as a JSON history file with separate image files. Nothing is uploaded. If a shortcut does not work, another app may have claimed it: open Settings and select another combination. If you cannot see the tray icon, open the hidden-icons arrow beside the clock.", "Body"),
          p("Download current builds: <link href='https://github.com/Digimo2020/ClipStack/releases/latest' color='#7048E8'>GitHub Releases</link> · Source code: <link href='https://github.com/Digimo2020/ClipStack' color='#7048E8'>github.com/Digimo2020/ClipStack</link>.", "Callout")]

doc.build(story, onFirstPage=footer, onLaterPages=footer)
print(OUT)
