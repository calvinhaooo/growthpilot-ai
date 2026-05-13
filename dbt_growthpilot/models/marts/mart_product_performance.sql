with order_items as (
    select *
    from {{ ref('stage_order_items') }}
),
products as (
    select *
    from {{ ref('stage_products') }}
),
enriched as (
    select
        -- time dimensions
        oi.order_item_date as date,
        oi.order_item_week as week_start,
        --  product dimensions
        oi.product_id,
        coalesce(p.product_name, 'Unknown') as product_name,
        coalesce(p.brand, 'Unknown') as brand,
        coalesce(p.category, 'Unknown') as category,
        coalesce(p.department, 'Unknown') as department,

        --  transaction identifiers
        oi.order_item_id,
        oi.order_id,
        oi.user_id,
        -- item status
        coalesce(oi.item_status, 'Unknown') as item_status,

        -- price and cost 
        oi.sale_price,
        coalesce(p.cost, 0) as cost,
        p.retail_price,

        oi.sale_price - coalesce(p.cost, 0) as item_gross_profit
    from order_items as oi
    left join products as p on oi.product_id = p.product_id
),
product_kpis_base as (
    select
        date,
        week_start,
        product_id,
        product_name,
        brand,
        category,
        department,

        count(distinct order_id) as orders,
        count(distinct user_id) as customers,
        count(order_item_id) as units_sold,

        round(sum(sale_price), 2) as gross_revenue,

        round(
            sum(
                case 
                    when lower(item_status) not in ('returned', 'cancelled') then sale_price
                    else 0
                end
            ), 2
        ) as net_revenue,

        round(avg(sale_price), 2) as avg_selling_price,

        round(
            sum(
                case 
                    when lower(item_status) not in ('returned', 'cancelled') then item_gross_profit
                    else 0
                end
            ), 2
        ) as gross_profit,

        countif(lower(item_status) = 'returned') as returned_items,
        countif(lower(item_status) = 'cancelled') as cancelled_items,

        round(
            safe_divide(
                countif(lower(item_status) = 'returned'), count(order_item_id)
            ), 4
        ) as item_return_rate,

        round(
            safe_divide(
                countif(lower(item_status) = 'cancelled'), count(order_item_id)
            ), 4
        ) as item_cancellation_rate
    from enriched 
    group by date, week_start, product_id, product_name, brand, category, department
),
final as (
    select *,
    round(
        safe_divide(gross_profit, net_revenue), 4
    ) as gross_margin
    from product_kpis_base
)

select *
from final
