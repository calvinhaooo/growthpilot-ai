-- Product opportunity table for growth actions based on sales, margin, return rate, and inventory health

with product_history as (

    select
        product_id,

        any_value(product_name) as product_name,
        any_value(category) as category,
        any_value(brand) as brand,
        any_value(department) as department,

        sum(orders) as orders,
        sum(customers) as product_buyer_records,
        sum(units_sold) as units_sold,

        round(sum(gross_revenue), 2) as gross_revenue,
        round(sum(net_revenue), 2) as net_revenue,
        round(sum(gross_profit), 2) as gross_profit,

        round(
            safe_divide(sum(gross_profit), sum(net_revenue)),
            4
        ) as gross_margin,

        sum(returned_items) as returned_items,
        sum(cancelled_items) as cancelled_items,

        round(
            safe_divide(sum(returned_items), sum(units_sold)),
            4
        ) as item_return_rate,

        round(
            safe_divide(sum(cancelled_items), sum(units_sold)),
            4
        ) as item_cancellation_rate,

        min(date) as first_sale_date,
        max(date) as last_sale_date

    from {{ ref('mart_product_performance') }}

    group by
        product_id

),

inventory as (

    select
        product_id,
        available_inventory,
        sell_through_rate,
        avg_days_to_sell,
        inventory_health_status

    from {{ ref('mart_inventory_health') }}

),

scored as (

    select
        ph.product_id,
        ph.product_name,
        ph.category,
        ph.brand,
        ph.department,

        ph.orders,
        ph.product_buyer_records,
        ph.units_sold,
        ph.gross_revenue,
        ph.net_revenue,
        ph.gross_profit,
        ph.gross_margin,

        ph.returned_items,
        ph.cancelled_items,
        ph.item_return_rate,
        ph.item_cancellation_rate,

        ph.first_sale_date,
        ph.last_sale_date,

        coalesce(i.available_inventory, 0) as available_inventory,
        i.sell_through_rate,
        i.avg_days_to_sell,
        coalesce(i.inventory_health_status, 'Unknown') as inventory_health_status,

        case
            when ph.net_revenue >= 1000
                 and ph.gross_margin >= 0.5
                 and coalesce(i.inventory_health_status, 'Unknown') in ('Healthy Movement', 'Monitor')
                then 'Scale marketing'

            when ph.net_revenue >= 1000
                 and ph.item_return_rate >= 0.2
                then 'Review product quality or positioning'

            when coalesce(i.inventory_health_status, 'Unknown') = 'High stockout Risk'
                then 'Check inventory before scaling'

            when coalesce(i.inventory_health_status, 'Unknown') = 'Out of Stock'
                then 'Do not promote until restocked'

            when coalesce(i.inventory_health_status, 'Unknown') = 'potential overstock'
                then 'Consider promotion or markdown'

            else 'Monitor'
        end as recommended_action

    from product_history as ph

    left join inventory as i
        on ph.product_id = i.product_id

),

final as (

    select
        *,

        case
            when recommended_action = 'Scale marketing' then 1
            when recommended_action = 'Check inventory before scaling' then 2
            when recommended_action = 'Review product quality or positioning' then 3
            when recommended_action = 'Consider promotion or markdown' then 4
            when recommended_action = 'Do not promote until restocked' then 5
            else 6
        end as action_priority

    from scored

)

select *
from final