select
    id as user_id,
    first_name,
    last_name,
    email,
    age,
    gender,
    state,
    street_address,
    postal_code,
    city,
    country,
    latitude,
    longitude,
    traffic_source,
    created_at,

    date(created_at) as user_created_date

from {{ source('thelook_ecommerce', 'users') }}
where created_at is not null