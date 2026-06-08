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

conversions as (

    select
        event_timestamp,
        client_id,
        session_id,
        event_name      as conversion_event,
        form_name,
        interest,
        company_size,
        job_title,
        page_location

    from events
    where event_name in unnest({{ conversion_events }})

)

select * from conversions
