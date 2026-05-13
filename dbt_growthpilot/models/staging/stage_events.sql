select
    id as event_id,
    user_id,
    sequence_number,
    session_id,
    created_at,
    ip_address,
    city,
    state,
    postal_code,
    browser,
    traffic_source,
    uri,
    event_type,

    date(created_at) as event_date,
    date_trunc(date(created_at), week(monday)) as event_week

from {{ source('thelook_ecommerce', 'events') }}
where created_at is not null