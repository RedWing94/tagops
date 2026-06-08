with events as (

    select * from {{ ref('stg_events') }}

),

page_views as (

    select
        event_timestamp,
        client_id,
        session_id,
        page_location,
        page_title,
        page_referrer,
        geo_country,
        geo_region

    from events
    where event_name = 'page_view'

)

select * from page_views
