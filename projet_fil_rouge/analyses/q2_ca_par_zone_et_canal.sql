SELECT
    g.zone,
    f.canal_vente,
    SUM(f.chiffre_affaires) AS ca,
    COUNT(DISTINCT f.commande_id) AS nb_commandes
FROM {{ ref('fct_ventes') }} f
JOIN {{ ref('dim_geographie') }} g ON g.geographie_id = f.geographie_id
GROUP BY g.zone, f.canal_vente
ORDER BY g.zone, ca DESC
