SELECT
    geographie_id,
    ville,
    pays,
    zone
FROM {{ ref('stg_nike__dim_geographie') }}
