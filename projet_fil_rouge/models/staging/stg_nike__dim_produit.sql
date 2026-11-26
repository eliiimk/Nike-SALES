SELECT
    produit_id,
    TRIM(nom) AS nom,
    niveau,
    parent_id,
    TRIM(categorie) AS categorie,
    TRIM(univers) AS univers,
    prix_catalogue
FROM {{ source('nike', 'dim_produit') }}
