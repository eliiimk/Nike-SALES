SELECT
    d.annee,
    p.categorie,
    SUM(f.chiffre_affaires) AS ca,
    SUM(f.quantite_vendue) AS quantite
FROM {{ ref('fct_ventes') }} f
JOIN {{ ref('dim_date') }} d ON d.date_id = f.date_id
JOIN {{ ref('dim_produit') }} p ON p.produit_id = f.produit_id
GROUP BY d.annee, p.categorie
ORDER BY d.annee, ca DESC
