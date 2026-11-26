SELECT
    produit_id,
    nom,
    categorie,
    univers,
    prix_catalogue
FROM {{ ref('stg_nike__dim_produit') }}
WHERE niveau = 'Produit'
