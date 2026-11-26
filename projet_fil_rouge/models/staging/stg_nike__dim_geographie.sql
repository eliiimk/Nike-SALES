SELECT
    geographie_id,
    TRIM(ville) AS ville,
    TRIM(pays) AS pays,
    TRIM(zone) AS zone
FROM {{ source('nike', 'dim_geographie') }}
