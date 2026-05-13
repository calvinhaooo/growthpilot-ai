select
    id as inventory_item_id,
    product_id,
    created_at,
    sold_at,
    cost,
    product_category,
    product_name,
    product_brand,
    product_retail_price,
    product_department,
    product_sku,
    product_distribution_center_id,

    date(created_at) as inventory_created_date,
    date(sold_at) as inventory_sold_date

from {{ source('thelook_ecommerce', 'inventory_items') }}
where created_at is not null