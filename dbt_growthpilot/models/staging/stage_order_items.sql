select
    id as order_item_id,
    order_id,
    user_id,
    product_id,
    inventory_item_id,
    status as item_status,
    created_at,
    shipped_at,
    delivered_at,
    returned_at,
    sale_price,

    date(created_at) as order_item_date,
    date_trunc(date(created_at), week(monday)) as order_item_week

from {{ source('thelook_ecommerce', 'order_items') }}
where created_at is not null