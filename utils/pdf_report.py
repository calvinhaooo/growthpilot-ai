from pathlib import Path

import markdown
from bs4 import BeautifulSoup
from reportlab.lib import colors
from reportlab.lib.enums import TA_LEFT
from reportlab.lib.pagesizes import A4
from reportlab.lib.styles import ParagraphStyle, getSampleStyleSheet
from reportlab.lib.units import cm
from reportlab.platypus import (
    HRFlowable,
    ListFlowable,
    ListItem,
    Paragraph,
    SimpleDocTemplate,
    Spacer,
)


def clean_markdown_for_pdf(text: str) -> str:
    """Light cleanup so markdown text renders more safely in ReportLab."""
    replacements = {
        "→": "->",
        "–": "-",
        "—": "-",
        "“": '"',
        "”": '"',
        "’": "'",
    }

    for old, new in replacements.items():
        text = text.replace(old, new)

    return text


def _build_styles():
    styles = getSampleStyleSheet()

    styles.add(
        ParagraphStyle(
            name="ReportTitle",
            parent=styles["Title"],
            fontName="Helvetica-Bold",
            fontSize=18,
            leading=22,
            spaceAfter=14,
            alignment=TA_LEFT,
        )
    )

    styles.add(
        ParagraphStyle(
            name="SectionHeading",
            parent=styles["Heading2"],
            fontName="Helvetica-Bold",
            fontSize=13,
            leading=16,
            spaceBefore=12,
            spaceAfter=7,
            textColor=colors.HexColor("#1F2937"),
        )
    )

    styles.add(
        ParagraphStyle(
            name="SubHeading",
            parent=styles["Heading3"],
            fontName="Helvetica-Bold",
            fontSize=11,
            leading=14,
            spaceBefore=8,
            spaceAfter=5,
            textColor=colors.HexColor("#374151"),
        )
    )

    styles.add(
        ParagraphStyle(
            name="ReportBody",
            parent=styles["BodyText"],
            fontName="Helvetica",
            fontSize=9.5,
            leading=13,
            spaceAfter=5,
        )
    )

    styles.add(
        ParagraphStyle(
            name="ReportBullet",
            parent=styles["BodyText"],
            fontName="Helvetica",
            fontSize=9.5,
            leading=13,
            leftIndent=12,
            firstLineIndent=0,
            spaceAfter=4,
        )
    )

    return styles


def _paragraph_from_html(element, style):
    text = "".join(str(x) for x in element.contents)
    text = text.replace("<strong>", "<b>").replace("</strong>", "</b>")
    text = text.replace("<em>", "<i>").replace("</em>", "</i>")
    return Paragraph(text, style)


def _list_item_from_html(li, style):
    text = "".join(str(x) for x in li.contents)
    text = text.replace("<strong>", "<b>").replace("</strong>", "</b>")
    text = text.replace("<em>", "<i>").replace("</em>", "</i>")
    return ListItem(
        Paragraph(text, style),
        bulletColor=colors.HexColor("#374151"),
    )


def write_pdf_report(report_text: str, output_path: Path) -> None:
    """
    Convert a markdown report into a formatted PDF.

    This is intentionally lightweight:
    markdown -> html -> ReportLab paragraphs/lists.
    """
    report_text = clean_markdown_for_pdf(report_text)

    html = markdown.markdown(report_text, extensions=["extra"])
    soup = BeautifulSoup(html, "html.parser")

    doc = SimpleDocTemplate(
        str(output_path),
        pagesize=A4,
        rightMargin=1.8 * cm,
        leftMargin=1.8 * cm,
        topMargin=1.7 * cm,
        bottomMargin=1.7 * cm,
        title="Weekly Growth Report",
    )

    styles = _build_styles()
    story = []

    for element in soup.children:
        if element.name is None:
            continue

        if element.name == "h1":
            story.append(_paragraph_from_html(element, styles["ReportTitle"]))

        elif element.name == "h2":
            story.append(_paragraph_from_html(element, styles["SectionHeading"]))

        elif element.name == "h3":
            story.append(_paragraph_from_html(element, styles["SubHeading"]))

        elif element.name == "p":
            story.append(_paragraph_from_html(element, styles["ReportBody"]))

        elif element.name == "hr":
            story.append(Spacer(1, 0.15 * cm))
            story.append(
                HRFlowable(
                    width="100%",
                    color=colors.HexColor("#D1D5DB"),
                    thickness=0.6,
                )
            )
            story.append(Spacer(1, 0.15 * cm))

        elif element.name == "ul":
            items = [
                _list_item_from_html(li, styles["ReportBullet"])
                for li in element.find_all("li", recursive=False)
            ]
            story.append(
                ListFlowable(
                    items,
                    bulletType="bullet",
                    leftIndent=14,
                    bulletFontName="Helvetica",
                    bulletFontSize=7,
                )
            )

        elif element.name == "ol":
            items = [
                _list_item_from_html(li, styles["ReportBullet"])
                for li in element.find_all("li", recursive=False)
            ]
            story.append(
                ListFlowable(
                    items,
                    bulletType="1",
                    leftIndent=16,
                )
            )

        story.append(Spacer(1, 0.08 * cm))

    doc.build(story)