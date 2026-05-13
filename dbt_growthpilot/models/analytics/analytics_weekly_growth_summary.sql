-- this table includes growth KPI traffic funnel product margin

with growth as (
    select
        week_start,

        sum(orders) as orders,
        sum(active_users) as active_users,
        sum(units_sold) as units_sold,

        round(sum(gross_revenue), 2) as gross_revenue,
        round(sum(net_revenue), 2) as net_revenue,

        round(
            safe_divide(sum(gross_revenue), sum(orders)), 2
        ) as avg_order_value,

        sum(returned_items) as returned_items,
        sum(cancelled_items) as cancelled_items,

        round(
            safe_divide(sum(returned_items), sum(units_sold)), 4
        ) as item_return_rate,
        round(
            safe_divide(sum(cancelled_items), sum(units_sold)), 4
        ) as item_cancellation_rate
    from {{ ref('mart_growth_kpis') }}
    group by week_start
),

traffic as (
    select
        week_start,

        sum(total_events) as total_events,
        sum(sessions) as sessions,
        sum(users) as traffic_users,

        sum(home_events) as home_events,
        sum(product_events) as product_events,
        sum(cart_events) as cart_events,
        sum(purchase_events) as purchase_events,

        round(
            safe_divide(sum(product_events), sum(sessions)), 4
        ) as product_view_rate,
        round(
            safe_divide(sum(cart_events), sum(product_events)), 4
        ) as cart_rate,
        round(
            safe_divide(sum(purchase_events), sum(cart_events)), 4
        ) as purchase_rate,
        round(
            safe_divide(sum(purchase_events), sum(sessions)), 4
        ) as session_conversion_rate
    from {{ ref('mart_traffic_funnel') }}
    group by week_start
),
product as (
    select
        week_start,
        count(distinct product_id) as active_products,

        round(sum(gross_revenue), 2) as product_gross_revenue,
        round(sum(net_revenue), 2) as product_net_revenue,
        round(sum(gross_profit), 2) as product_gross_profit,

        round(
            safe_divide(sum(gross_profit), sum(net_revenue)), 4
        ) as gross_margin,

        sum(returned_items) as product_returned_items,
        sum(cancelled_items) as product_cancelled_items
    from {{ ref('mart_product_performance') }}
    group by week_start
),
weekly_summary as (
    select
        g.week_start,

        g.orders,
        g.active_users,
        g.units_sold,
        g.gross_revenue,
        g.net_revenue,
        g.avg_order_value,
        g.returned_items,
        g.cancelled_items,
        g.item_return_rate,
        g.item_cancellation_rate,

        t.total_events,
        t.sessions,
        t.traffic_users,
        t.home_events,
        t.product_events,
        t.cart_events,
        t.purchase_events,
        t.product_view_rate,
        t.cart_rate,
        t.purchase_rate,
        t.session_conversion_rate,

        p.active_products,
        p.product_gross_revenue,
        p.product_net_revenue,
        p.product_gross_profit,
        p.gross_margin,
        p.product_returned_items,
        p.product_cancelled_items
    from growth as g
    left join traffic as t
        on g.week_start = t.week_start
    left join product as p
        on g.week_start = p.week_start
)

select * from weekly_summary
