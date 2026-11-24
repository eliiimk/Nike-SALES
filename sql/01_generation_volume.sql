INSERT INTO dim_client (client_id, sexe, tranche_age, ville_residence, pays_residence,
                        membre_nike, date_inscription)
SELECT c.client_id + k * 100000,
       c.sexe,
       c.tranche_age,
       c.ville_residence,
       c.pays_residence,
       random() < 0.6,
       c.date_inscription - (30 + random() * 365)::int
FROM dim_client c
CROSS JOIN generate_series(1, 67) AS k
WHERE c.client_id < 100000;

INSERT INTO fait_ventes (vente_id, commande_id, order_id_source, date_id, client_id, produit_id,
                         geographie_id, canal_vente, genre_cible, taille, quantite_vendue,
                         prix_unitaire, remise, chiffre_affaires, benefices)
WITH copies AS (
    SELECT f.vente_id + k * 200000    AS vente_id,
           f.commande_id + k * 200000 AS commande_id,
           LEAST(GREATEST(d.date_complete + (random() * 30 - 15)::int,
                          DATE '2023-07-26'), DATE '2025-07-22') AS nouvelle_date,
           f.client_id + k * 100000   AS client_id,
           f.produit_id,
           f.geographie_id,
           f.canal_vente,
           f.genre_cible,
           f.taille,
           CASE WHEN random() < 0.85 THEN 1 WHEN random() < 0.8 THEN 2 ELSE 3 END AS quantite_vendue,
           f.prix_unitaire,
           CASE WHEN random() < 0.75 THEN 0
                ELSE ROUND((0.10 + random() * 0.30)::numeric, 2) END AS remise,
           p.prix_catalogue
    FROM fait_ventes f
    JOIN dim_date d    ON d.date_id    = f.date_id
    JOIN dim_produit p ON p.produit_id = f.produit_id
    CROSS JOIN generate_series(1, 67) AS k
    WHERE f.vente_id < 200000
)
SELECT vente_id,
       commande_id,
       NULL,
       TO_CHAR(nouvelle_date, 'YYYYMMDD')::int,
       client_id,
       produit_id,
       geographie_id,
       canal_vente,
       genre_cible,
       taille,
       quantite_vendue,
       prix_unitaire,
       remise,
       ROUND(quantite_vendue * prix_unitaire * (1 - remise), 2),
       ROUND(quantite_vendue * prix_unitaire * (1 - remise) - quantite_vendue * prix_catalogue * 0.55, 2)
FROM copies;

ANALYZE;

SELECT 'fait_ventes' AS table_name, COUNT(*) AS nb_lignes FROM fait_ventes
UNION ALL
SELECT 'dim_client', COUNT(*) FROM dim_client;
