-- 3. Segmenter les commandes en quartiles de chiffre d'affaires
WITH ca_par_commande AS (
    SELECT
        fv.commande_id,
        fv.order_id_source,
        dd.date_complete AS date_commande,
        fv.canal_vente,
        SUM(fv.chiffre_affaires) AS ca_commande
    FROM fait_ventes AS fv
    JOIN dim_date AS dd
        ON dd.date_id = fv.date_id
    GROUP BY
        fv.commande_id,
        fv.order_id_source,
        dd.date_complete,
        fv.canal_vente
)
SELECT
    commande_id,
    order_id_source,
    date_commande,
    canal_vente,
    ca_commande,
    NTILE(4) OVER (ORDER BY ca_commande DESC) AS quartile,
    CASE NTILE(4) OVER (ORDER BY ca_commande DESC)
        WHEN 1 THEN 'Q1 · Top CA'
        WHEN 2 THEN 'Q2'
        WHEN 3 THEN 'Q3'
        WHEN 4 THEN 'Q4 · Plus faible CA'
    END AS segment_ca
FROM ca_par_commande
ORDER BY ca_commande DESC, commande_id;