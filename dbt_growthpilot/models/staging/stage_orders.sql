select
    order_id,
    user_id,
    order_id as order_number,
    status as order_status,
    gender,
    created_at,
    returned_at,
    shipped_at,
    delivered_at,
    num_of_item as number_of_items,

    date(created_at) as order_date,
    date_trunc(date(created_at), week(monday)) as order_week

from {{ source('thelook_ecommerce', 'orders') }}
where created_at is not null