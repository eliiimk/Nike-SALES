SELECT
    vente_id,
    commande_id,
    date_id,
    client_id,
    produit_id,
    geographie_id,
    canal_vente,
    genre_cible,
    taille,
    quantite_vendue,
    prix_unitaire,
    remise,
    chiffre_affaires,
    benefices
FROM {{ ref('stg_nike__fait_ventes') }}
