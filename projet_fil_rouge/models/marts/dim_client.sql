SELECT
    client_id,
    sexe,
    tranche_age,
    ville_residence,
    pays_residence,
    membre_nike,
    date_inscription
FROM {{ ref('stg_nike__dim_client') }}
