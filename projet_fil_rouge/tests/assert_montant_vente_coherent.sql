SELECT
    vente_id,
    quantite_vendue,
    prix_unitaire,
    remise,
    chiffre_affaires
FROM {{ ref('fct_ventes') }}
WHERE ABS(chiffre_affaires - quantite_vendue * prix_unitaire * (1 - remise)) > 0.01
