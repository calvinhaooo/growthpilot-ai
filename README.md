# GrowthPilot AI

GrowthPilot AI is an AI-powered e-commerce growth intelligence and automation project.

It simulates a multi-channel commerce environment using public e-commerce order data and synthetic paid media and inventory data. The goal is to help growth teams move from raw data to actionable insights through a trusted KPI layer, customer segmentation, demand forecasting, and LLM-generated weekly growth reports.

## Project Goal

This project is designed to demonstrate how data, AI, and automation can support growth decisions in an e-commerce business.

It covers:

- BigQuery-based data warehousing
- dbt data modeling
- Growth KPI framework
- Product and marketing performance analysis
- Customer segmentation
- Demand forecasting
- AI-generated weekly business reports
- Streamlit dashboard

## Tech Stack

- Python
- uv
- Google BigQuery
- dbt-bigquery
- pandas
- scikit-learn
- Streamlit
- Plotly
- LLM API

## Data

The project uses the public Olist Brazilian E-Commerce dataset and extends it with synthetic paid media and inventory data for portfolio purposes.

## Planned Pipeline

```text
Olist CSV data
+ synthetic ad spend and inventory data
        ↓
BigQuery raw dataset
        ↓
dbt staging models
        ↓
dbt mart models
        ↓
Python ML scripts
        ↓
LLM weekly report generator
        ↓
Streamlit dashboard