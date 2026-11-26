SELECT
    date_id,
    date_complete,
    annee,
    trimestre,
    mois,
    nom_mois,
    semaine,
    jour_semaine,
    nom_jour,
    est_weekend
FROM {{ ref('stg_nike__dim_date') }}
