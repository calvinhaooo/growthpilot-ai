with inventory as (
    select * from {{ ref('stage_inventory_items') }}
),
order_items as (
    select * from {{ ref('stage_order_items') }}
),
products as (
    select * from {{ ref('stage_products') }}
),
inventory_base as (
    select
        product_id,

        count(inventory_item_id) as inventory_items_created,
        countif(inventory_sold_date is not null) as inventory_items_sold,
        countif(inventory_sold_date is null) as available_inventory,

        round(
            safe_divide(
                countif(inventory_sold_date is not null),
                count(inventory_item_id)
            ), 4
        ) as sell_through_rate,

        round(
            avg(
                case 
                    when inventory_sold_date is not null 
                    then date_diff(inventory_sold_date, inventory_created_date, day)
                    end
            ), 2
        ) as avg_days_to_sell,

        min(inventory_created_date) as first_inventory_date,
        max(inventory_created_date) as last_inventory_date

    from inventory
    group by product_id
),
sales_base as (
    select
        product_id,

        count(distinct order_id) as historical_orders,
        count(order_item_id) as historical_units_sold,

        round(sum(sale_price), 2) as historical_gross_revenue,
        round(
            sum(
                case
                    when lower(item_status) not in ('returned', 'cancelled') then sale_price
                    else 0
                end
            ), 2
        ) as historical_net_revenue,

        countif(lower(item_status) = 'returned') as historical_returned_items,
        countif(lower(item_status) = 'cancelled') as historical_cancelled_items,

        round(
            safe_divide(
                countif(lower(item_status) = 'returned'), count(order_item_id)
            ), 4
        ) as historical_return_rate,

        round(
            safe_divide(
                countif(lower(item_status) = 'cancelled'), count(order_item_id)
            ), 4
        ) as historical_cancellation_rate,

        min(order_item_date) as first_sale_date,
        max(order_item_date) as last_sale_date

    from order_items
    group by product_id
),
final as (
    select
        ib.product_id,
        coalesce(p.product_name, 'Unknown') as product_name,
        coalesce(p.brand, 'Unknown') as brand,
        coalesce(p.category, 'Unknown') as category,
        coalesce(p.department, 'Unknown') as department,

        p.cost,
        p.retail_price,

        ib.inventory_items_created,
        ib.inventory_items_sold,
        ib.available_inventory,
        ib.sell_through_rate,
        ib.avg_days_to_sell,
        ib.first_inventory_date,
        ib.last_inventory_date,

        coalesce(sb.historical_orders, 0) as historical_orders,
        coalesce(sb.historical_units_sold, 0) as historical_units_sold,
        coalesce(sb.historical_gross_revenue, 0) as historical_gross_revenue,
        coalesce(sb.historical_net_revenue, 0) as historical_net_revenue,
        coalesce(sb.historical_returned_items, 0) as historical_returned_items,
        coalesce(sb.historical_cancelled_items, 0) as historical_cancelled_items,
        coalesce(sb.historical_return_rate, 0) as historical_return_rate,
        coalesce(sb.historical_cancellation_rate, 0) as historical_cancellation_rate,
        sb.first_sale_date,
        sb.last_sale_date,

        case 
            when ib.available_inventory = 0 then 'Out of Stock'
            when ib.sell_through_rate >= 0.8 and ib.available_inventory <=5 then 'High stockout Risk'
            when ib.sell_through_rate >= 0.6 then 'Healthy Movement'
            when ib.sell_through_rate < 0.2 and ib.available_inventory > 20 then 'potential overstock'
            else 'Monitor'
        end as inventory_health_status

    from inventory_base as ib
    left join sales_base as sb on ib.product_id = sb.product_id
    left join products as p on ib.product_id = p.product_id
)

select * from final