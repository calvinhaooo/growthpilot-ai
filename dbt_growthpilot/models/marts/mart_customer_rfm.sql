-- Customer RFM base mart: recency, frequency, and monetary value for customer segmentation

with order_items as (
    select * from {{ ref('stage_order_items') }}
),
users as (
    select * from {{ ref('stage_users') }}
),
valid_orders as (
    select *
    from order_items
    where lower(item_status) not in ('returned', 'cancelled')
),
reference_date as (
    select max(order_item_date) as reference_date
    from valid_orders
),
customer_base as (
    select
        oi.user_id,
        min(oi.order_item_date) as first_purchase_date,
        max(oi.order_item_date) as last_purchase_date,
        count(distinct oi.order_id) as frequency,
        count(oi.order_item_id) as total_items_purchased,
        round(sum(oi.sale_price), 2) as monetary_value
    from valid_orders as oi
    group by oi.user_id
),
final as (
    select
        cb.user_id,

        u.traffic_source,
        u.country,
        u.city,
        u.age,
        u.gender,

        cb.first_purchase_date,
        cb.last_purchase_date,

        date_diff(rd.reference_date, cb.last_purchase_date, day) as recency_days,

        cb.frequency,
        cb.total_items_purchased,
        cb.monetary_value,

        round(
            safe_divide(cb.monetary_value, cb.frequency), 2
        ) as avg_order_value

    from customer_base as cb
    left join users as u on cb.user_id = u.user_id
    cross join reference_date as rd
)

select * from final