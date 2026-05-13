with order_items as (
    select *
    from {{ ref('stage_order_items') }}
),
orders as (
    select *
    from {{ ref('stage_orders') }}
),
users as (
    select *
    from {{ ref('stage_users') }}
),
enriched as (
    select
        oi.order_item_date as date,
        oi.order_item_week as week_start,
        coalesce(u.traffic_source, 'Unknown') as traffic_source,
        coalesce(o.order_status, 'Unknown') as order_status,
        coalesce(oi.item_status, 'Unknown') as item_status,
        oi.order_item_id,
        oi.order_id,
        oi.user_id,
        oi.product_id,
        oi.sale_price
    from order_items as oi
    left join orders as o
        on oi.order_id = o.order_id
    left join users as u
        on oi.user_id = u.user_id
),
daily_kpis as (
    select 
        date,
        week_start,
        traffic_source,
        count(distinct order_id) as orders,
        count(distinct user_id) as active_users,
        count(order_item_id) as units_sold,
        round(sum(sale_price), 2) as gross_revenue,
        -- net_revenue --> valid revenue
        round(
            sum(
                case 
                    when lower(item_status) not in ('returned', 'cancelled') then sale_price
                    else 0
                end
            ), 2
        ) as net_revenue,

        round(
            safe_divide(
                sum(sale_price), count(distinct order_id)
            ), 2
        ) as avg_order_value,

        countif(lower(item_status) = 'returned') as returned_items,
        countif(lower(item_status) = 'cancelled') as cancelled_items,
        
        round(
            safe_divide(
                countif(lower(item_status) = 'returned'),
                count(order_item_id)
            ), 4
        ) as item_return_rate,
        round(
            safe_divide(
                countif(lower(item_status) = 'cancelled'),
                count(order_item_id)
            ), 4
        ) as item_cancellation_rate
    from enriched
    group by 1, 2, 3
)

select *
from daily_kpis
