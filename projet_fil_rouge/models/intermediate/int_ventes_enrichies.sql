{{ config(materialized='view') }}

SELECT
    fv.vente_id,
    fv.commande_id,
    fv.date_id,
    dd.annee,
    dd.mois,
    fv.client_id,
    dc.ville_residence,
    fv.produit_id,
    dp.categorie,
    dp.nom,
    fv.geographie_id,
    dg.ville,
    dg.pays,
    fv.canal_vente,
    fv.genre_cible,
    fv.taille,
    fv.quantite_vendue,
    fv.prix_unitaire,
    fv.remise,
    fv.chiffre_affaires
FROM {{ ref('stg_nike__fait_ventes') }} AS fv
LEFT JOIN {{ ref('stg_nike__dim_produit') }} AS dp
    ON fv.produit_id = dp.produit_id
LEFT JOIN {{ ref('stg_nike__dim_date') }} AS dd
    ON fv.date_id = dd.date_id
LEFT JOIN {{ ref('stg_nike__dim_geographie') }} AS dg
    ON fv.geographie_id = dg.geographie_id
LEFT JOIN {{ ref('stg_nike__dim_client') }} AS dc
    ON fv.client_id = dc.client_id
