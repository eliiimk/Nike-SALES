SELECT
    c.membre_nike,
    COUNT(DISTINCT f.client_id) AS nb_clients,
    SUM(f.chiffre_affaires) AS ca,
    ROUND(SUM(f.chiffre_affaires) / COUNT(DISTINCT f.client_id), 2) AS ca_par_client
FROM {{ ref('fct_ventes') }} f
JOIN {{ ref('dim_client') }} c ON c.client_id = f.client_id
GROUP BY c.membre_nike
