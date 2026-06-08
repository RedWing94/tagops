{% set conversion_events = [
    'lead',
    'generate_lead',
    'get_in_touch',
    'purchase',
    'appointment_booked'
] %}

with events as (

    select * from {{ ref('stg_events') }}

),

sessions as (

    select
        client_id,
        session_id,
        min(event_timestamp)  as session_start,
        max(event_timestamp)  as session_end,

        countif(event_name = 'page_view')  as pageviews,
        count(*)                           as total_events,
        countif(event_name in unnest({{ conversion_events }}))  as conversions,

        max(geo_country)  as geo_country,
        max(geo_region)   as geo_region

    from events
    where session_id is not null
    group by client_id, session_id

)

select * from sessions
