SELECT
    vente_id,
    commande_id,
    date_id,
    client_id,
    produit_id,
    geographie_id,
    TRIM(canal_vente) AS canal_vente,
    TRIM(genre_cible) AS genre_cible,
    TRIM(CAST(taille AS VARCHAR)) AS taille,
    quantite_vendue,
    prix_unitaire,
    remise,
    chiffre_affaires,
    benefices
FROM {{ source('nike', 'fait_ventes') }}
