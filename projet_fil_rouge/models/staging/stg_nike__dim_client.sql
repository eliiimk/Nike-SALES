SELECT
    client_id,
    sexe,
    TRIM(tranche_age) AS tranche_age,
    TRIM(ville_residence) AS ville_residence,
    TRIM(pays_residence) AS pays_residence,
    membre_nike,
    date_inscription
FROM {{ source('nike', 'dim_client') }}
