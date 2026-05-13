import os

from dotenv import load_dotenv
from google.cloud import bigquery


def main() -> None:
    load_dotenv()

    project_id = os.getenv("GCP_PROJECT_ID")
    credentials_path = os.getenv("GOOGLE_APPLICATION_CREDENTIALS")

    if not project_id:
        raise ValueError("GCP_PROJECT_ID is missing. Please set it in your .env file.")

    if not credentials_path:
        raise ValueError(
            "GOOGLE_APPLICATION_CREDENTIALS is missing. Please set it in your .env file."
        )

    client = bigquery.Client.from_service_account_json(
        credentials_path,
        project=project_id,
    )

    query = """
    select
        count(*) as orders_count
    from `bigquery-public-data.thelook_ecommerce.orders`
    """

    result = client.query(query).result()

    for row in result:
        print("BigQuery connection works.")
        print(f"Orders count: {row.orders_count:,}")


if __name__ == "__main__":
    main()