{{ config(materialized='view') }}

SELECT
    annee,
    mois,
    categorie,
    nom,
    COUNT(DISTINCT commande_id) AS nb_commandes,
    SUM(quantite_vendue) AS quantite_totale,
    ROUND(SUM(chiffre_affaires), 2) AS ca_produit
FROM {{ ref('int_ventes_enrichies') }}
WHERE canal_vente = 'Online'
GROUP BY
    annee,
    mois,
    categorie,
    nom
