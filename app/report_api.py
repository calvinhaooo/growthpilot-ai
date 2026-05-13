import subprocess
from pathlib import Path

from fastapi import FastAPI
from fastapi.responses import FileResponse, JSONResponse


ROOT_DIR = Path(__file__).resolve().parents[1]
REPORT_SCRIPT = ROOT_DIR / "scripts" / "generate_weekly_report.py"
OUTPUT_PDF = ROOT_DIR / "outputs" / "weekly_growth_report_ai.pdf"
OUTPUT_MD = ROOT_DIR / "outputs" / "weekly_growth_report_ai.md"

app = FastAPI(title="GrowthPilot AI Report API")


@app.get("/")
def health_check():
    return {"status": "ok", "service": "GrowthPilot AI Report API"}


@app.post("/generate-weekly-report")
def generate_weekly_report():
    if not REPORT_SCRIPT.exists():
        return JSONResponse(
            status_code=500,
            content={"status": "error", "message": f"Script not found: {REPORT_SCRIPT}"},
        )

    result = subprocess.run(
        ["uv", "run", "python", str(REPORT_SCRIPT)],
        cwd=str(ROOT_DIR),
        capture_output=True,
        text=True,
    )

    if result.returncode != 0:
        return JSONResponse(
            status_code=500,
            content={
                "status": "error",
                "message": "Report generation failed",
                "stdout": result.stdout,
                "stderr": result.stderr,
            },
        )

    return {
        "status": "success",
        "message": "Weekly growth report generated",
        "markdown_path": str(OUTPUT_MD),
        "pdf_path": str(OUTPUT_PDF),
        "stdout": result.stdout[-1000:],
    }


@app.get("/download-weekly-report")
def download_weekly_report():
    if not OUTPUT_PDF.exists():
        return JSONResponse(
            status_code=404,
            content={"status": "error", "message": "PDF report not found. Generate it first."},
        )

    return FileResponse(
        path=str(OUTPUT_PDF),
        filename="weekly_growth_report_ai.pdf",
        media_type="application/pdf",
    )