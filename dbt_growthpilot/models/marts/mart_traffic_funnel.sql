with events as (
    select *
    from {{ ref('stage_events') }}
),
daily_funnel as (
    select
        event_date as date,
        event_week as week_start,
        coalesce(traffic_source, 'Unknown') as traffic_source,

        count(*) as total_events,
        count(distinct session_id) as sessions,
        count(distinct user_id) as users,
        countif(lower(event_type) = 'home') as home_events,
        countif(lower(event_type) = 'product') as product_events,
        countif(lower(event_type) = 'cart') as cart_events,
        countif(lower(event_type) = 'purchase') as purchase_events,
        -- product view rate
        round(
            safe_divide(countif(lower(event_type) = 'product'), count(distinct session_id)
            ), 4
        ) as product_views_per_session,
        -- cart add rate
        round(
            safe_divide(countif(lower(event_type) = 'cart'), countif( lower(event_type) = 'product')
            ), 4
        ) as cart_events_per_product_view,
        -- purchase rate from cart to purchase conversion rate
        round(
            safe_divide(countif(lower(event_type) = 'purchase'), countif(lower(event_type) = 'cart'))
            , 4
        ) as purchase_rate_per_cart,
        -- session_conversion_rate
        round(
            safe_divide(countif(lower(event_type) = 'purchase'), count(distinct session_id)
            ), 4
        ) as session_purchase_rate
    from events
    group by 1, 2, 3
)

select * from daily_funnel