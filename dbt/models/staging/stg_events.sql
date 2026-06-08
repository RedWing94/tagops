with source as (

    select * from {{ source('tagops_analytics', 'events') }}

),

staged as (

    select
        -- Core fields
        event_name,
        timestamp_millis(event_timestamp)                                   as event_timestamp,
        client_id,

        -- Session
        json_value(event_data, '$.ga_session_id')                           as session_id,
        safe_cast(json_value(event_data, '$.ga_session_number') as int64)   as session_number,

        -- Page context
        page_location,
        page_referrer,
        page_title,

        -- Geo (parsed from event_data)
        json_value(event_data, '$.event_location.country')                  as geo_country,
        json_value(event_data, '$.event_location.region')                   as geo_region,

        -- Lead / form fields
        json_value(event_data, '$.form_name')                               as form_name,
        json_value(event_data, '$.interest')                                as interest,
        json_value(event_data, '$.company_size')                            as company_size,
        json_value(event_data, '$.job_title')                               as job_title,

        -- Engagement
        safe_cast(json_value(event_data, '$.percent_scrolled') as int64)    as percent_scrolled,
        safe_cast(json_value(event_data, '$.engagement_time_msec') as int64) as engagement_time_msec,

        -- Raw payload
        event_data                                                          as raw_event_data

    from source

)

select * from staged
