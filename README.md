# GrowthPilot AI

GenAI automation project for turning trusted e-commerce analytics outputs into recurring business-ready weekly growth reports.

Core principle: BigQuery and dbt calculate trusted KPIs; the LLM only interprets metrics and writes business recommendations.

## Quick overview
- Purpose: Turn trusted e-commerce analytics into recurring, business-ready weekly growth reports.
- Key features: Trusted KPI layer, customer cohorts, analytics tables, LLM report generation, automated weekly delivery.

## Data
Primary data source: BigQuery public dataset: bigquery-public-data.thelook_ecommerce

## Tech stack
- BigQuery
- dbt
- Python
- uv
- pandas
- scikit-learn
- Jupyter
- OpenAI API
- ReportLab
- Markdown
- BeautifulSoup
- GitHub Actions
- Zapier

## Architecture (high level)
BigQuery public dataset
→ dbt staging
→ dbt marts
→ dbt analytics
→ Jupyter customer segmentation
→ OpenAI LLM report generator
→ Markdown/PDF output
→ GitHub Actions
→ Zapier scheduled trigger

## dbt layers
- growthpilot_staging
- growthpilot_marts
- growthpilot_analytics

## Staging models
- stage_orders
- stage_order_items
- stage_users
- stage_products
- stage_events
- stage_inventory_items

## Mart models
- mart_growth_kpis
- mart_product_performance
- mart_traffic_funnel
- mart_customer_rfm
- mart_inventory_health

## Analytics tables
- analytics_weekly_growth_summary
- analytics_product_opportunities
- customer_segments

## Customer segmentation
RFM features:
- recency_days
- frequency
- monetary_value

Method:
- log transform
- StandardScaler
- KMeans

Notebook:
- notebooks/01_customer_segmentation.ipynb

## LLM report generation
Script:
- scripts/03_generate_ai_growth_report.py

Outputs:
- outputs/weekly_growth_report_ai.md
- outputs/weekly_growth_report_ai.pdf

Local run:
- uv run python scripts/03_generate_ai_growth_report.py

## Automation workflow
Zapier Schedule Trigger
→ GitHub repository_dispatch
→ GitHub Actions
→ Python report generator
→ BigQuery analytics tables
→ OpenAI LLM
→ Markdown/PDF artifact

Workflow file:
- .github/workflows/generate-weekly-report.yml

Zapier setup:
- Schedule by Zapier: Every Week
- Webhooks by Zapier: Custom Request
- POST https://api.github.com/repos/<username>/<repo>/dispatches
- Body: { "event_type": "generate_weekly_report" }

## Local setup
- uv sync

dbt commands (local):
- cd dbt_growthpilot
- uv run dbt debug
- uv run dbt run

## Environment variables
- GCP_PROJECT_ID
- BQ_ANALYTICS_DATASET
- GOOGLE_APPLICATION_CREDENTIALS
- OPENAI_API_KEY

## GitHub Actions secrets
- GCP_PROJECT_ID
- BQ_ANALYTICS_DATASET
- GCP_SERVICE_ACCOUNT_JSON
- OPENAI_API_KEY

## Future Improvements
- Streamlit dashboard
- BQML forecasting
- Anomaly detection
- Google Drive or Gmail delivery
- Zapier MCP extension
- dbt tests and docs

## Project positioning
GenAI automation project for turning trusted e-commerce analytics outputs into recurring business-ready weekly growth reports.
