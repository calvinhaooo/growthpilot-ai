import json
import os
import sys
from pathlib import Path

import pandas as pd
from dotenv import load_dotenv
from google.cloud import bigquery
from google.oauth2 import service_account
from openai import OpenAI


ROOT_DIR = Path(__file__).resolve().parents[1]
sys.path.append(str(ROOT_DIR))

from utils.pdf_report import write_pdf_report


load_dotenv(ROOT_DIR / ".env")


PROJECT_ID = os.getenv("GCP_PROJECT_ID")
ANALYTICS_DATASET = os.getenv("BQ_ANALYTICS_DATASET", "growthpilot_analytics")
KEY_PATH = os.getenv("GOOGLE_APPLICATION_CREDENTIALS")
GCP_SERVICE_ACCOUNT_JSON = os.getenv("GCP_SERVICE_ACCOUNT_JSON")
OPENAI_API_KEY = os.getenv("OPENAI_API_KEY")


if not PROJECT_ID:
    raise ValueError("GCP_PROJECT_ID is missing.")

if not OPENAI_API_KEY:
    raise ValueError("OPENAI_API_KEY is missing.")

if not KEY_PATH and not GCP_SERVICE_ACCOUNT_JSON:
    raise ValueError(
        "Either GOOGLE_APPLICATION_CREDENTIALS or GCP_SERVICE_ACCOUNT_JSON is required."
    )


if GCP_SERVICE_ACCOUNT_JSON:
    service_account_info = json.loads(GCP_SERVICE_ACCOUNT_JSON)

    credentials = service_account.Credentials.from_service_account_info(
        service_account_info
    )

    bq_client = bigquery.Client(
        credentials=credentials,
        project=PROJECT_ID,
    )

else:
    if KEY_PATH.startswith("./"):
        KEY_PATH = str((ROOT_DIR / KEY_PATH).resolve())

    bq_client = bigquery.Client.from_service_account_json(
        KEY_PATH,
        project=PROJECT_ID,
    )


openai_client = OpenAI(api_key=OPENAI_API_KEY)


def pct_change(current, previous):
    if previous is None or previous == 0 or pd.isna(previous):
        return None
    return (current - previous) / previous


def clean_value(value):
    if pd.isna(value):
        return None

    if hasattr(value, "isoformat"):
        return value.isoformat()

    return value


def to_records(df: pd.DataFrame) -> list[dict]:
    rows = df.to_dict(orient="records")

    return [
        {key: clean_value(value) for key, value in row.items()}
        for row in rows
    ]


weekly_query = f"""
select *
from `{PROJECT_ID}.{ANALYTICS_DATASET}.analytics_weekly_growth_summary`
order by week_start desc
limit 2
"""

product_query = f"""
select
    product_id,
    product_name,
    category,
    brand,
    net_revenue,
    gross_margin,
    item_return_rate,
    available_inventory,
    sell_through_rate,
    inventory_health_status,
    recommended_action,
    action_priority
from `{PROJECT_ID}.{ANALYTICS_DATASET}.analytics_product_opportunities`
order by action_priority, net_revenue desc
limit 15
"""

segment_query = f"""
select
    segment_name,
    count(*) as customers,
    round(avg(recency_days), 2) as avg_recency_days,
    round(avg(frequency), 2) as avg_frequency,
    round(avg(monetary_value), 2) as avg_monetary_value,
    round(avg(avg_order_value), 2) as avg_order_value,
    round(sum(monetary_value), 2) as total_monetary_value
from `{PROJECT_ID}.{ANALYTICS_DATASET}.customer_segments`
group by segment_name
order by total_monetary_value desc
"""


weekly_df = bq_client.query(weekly_query).to_dataframe()
product_df = bq_client.query(product_query).to_dataframe()
segment_df = bq_client.query(segment_query).to_dataframe()


if weekly_df.empty:
    raise ValueError("No rows found in analytics_weekly_growth_summary.")


current = weekly_df.iloc[0]
previous = weekly_df.iloc[1] if len(weekly_df) > 1 else None


wow_changes = {
    "net_revenue_change": pct_change(
        current["net_revenue"],
        previous["net_revenue"] if previous is not None else None,
    ),
    "orders_change": pct_change(
        current["orders"],
        previous["orders"] if previous is not None else None,
    ),
    "session_conversion_rate_change": pct_change(
        current["session_conversion_rate"],
        previous["session_conversion_rate"] if previous is not None else None,
    ),
}


llm_input = {
    "current_week": to_records(weekly_df.head(1))[0],
    "previous_week": to_records(weekly_df.iloc[[1]])[0]
    if len(weekly_df) > 1
    else None,
    "week_over_week_changes": wow_changes,
    "top_product_opportunities": to_records(product_df.head(15)),
    "customer_segments": to_records(segment_df),
}


prompt = f"""
You are an AI analytics assistant for an e-commerce growth team.

You are given validated KPI outputs from a BigQuery and dbt analytics pipeline.
The metrics have already been calculated by SQL models.

Rules:
- Do not invent numbers.
- Do not claim a metric changed unless the change is present in the data.
- If a value is null or missing, say that the data is unavailable rather than guessing.
- Do not write as a chatbot.
- Do not end with offers, follow-up questions, or phrases like "If you want".

Your task:
Write a concise weekly growth report for a Head of Growth.

The report should include:
1. Executive summary
2. Growth performance
3. Traffic funnel interpretation
4. Product opportunities and risks
5. Customer segment insights
6. Recommended actions for next week

Writing style:
- Clear business English
- Practical and action oriented
- Explain what the numbers mean, not just repeat them
- Avoid technical SQL or data engineering language
- Use short sections
- Use bullet points where helpful
- Write as a finished business report, not as a chatbot response.

Data:
{json.dumps(llm_input, indent=2)}
"""


response = openai_client.responses.create(
    model="gpt-5.2",
    input=prompt,
)

ai_report = response.output_text


output_dir = ROOT_DIR / "outputs"
output_dir.mkdir(exist_ok=True)

md_output_path = output_dir / "weekly_growth_report_ai.md"
pdf_output_path = output_dir / "weekly_growth_report_ai.pdf"

md_output_path.write_text(ai_report, encoding="utf-8")
write_pdf_report(ai_report, pdf_output_path)


print(f"AI markdown report written to {md_output_path}")
print(f"AI PDF report written to {pdf_output_path}")
print()
print(ai_report)