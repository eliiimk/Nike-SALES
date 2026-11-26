SELECT
    date_id,
    date_complete,
    annee,
    trimestre,
    mois,
    TRIM(nom_mois) AS nom_mois,
    semaine,
    jour_semaine,
    TRIM(nom_jour) AS nom_jour,
    est_weekend
FROM {{ source('nike', 'dim_date') }}
