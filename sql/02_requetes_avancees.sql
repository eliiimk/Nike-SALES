-- Evolution des quantités achetées par client
SELECT
    client_id,
    date_id,
    quantite_vendue,
    LAG(quantite_vendue) OVER (
        PARTITION BY client_id
        ORDER BY date_id
    ) AS quantite_precedente
FROM fait_ventes;

-- Pays ayant connu la plus forte croissance de chiffre d'affaires
-- entre le S1 2024 et le S1 2025 dans chaque zone
WITH ventes_semestre AS (
    SELECT g.zone, g.pays, d.annee, f.chiffre_affaires
    FROM fait_ventes f
    JOIN dim_date d       ON d.date_id = f.date_id
    JOIN dim_geographie g ON g.geographie_id = f.geographie_id
    WHERE d.mois BETWEEN 1 AND 6
      AND d.annee IN (2024, 2025)
),
ca_pays AS (
    SELECT zone,
           pays,
           SUM(CASE WHEN annee = 2024 THEN chiffre_affaires ELSE 0 END) AS ca_2024,
           SUM(CASE WHEN annee = 2025 THEN chiffre_affaires ELSE 0 END) AS ca_2025
    FROM ventes_semestre
    GROUP BY zone, pays
),
evolution AS (
    SELECT *,
           ROUND(100.0 * (ca_2025 - ca_2024) / NULLIF(ca_2024,0), 1) AS evolution_pct
    FROM ca_pays
),
classement AS (
    SELECT *,
           RANK() OVER (
               PARTITION BY zone
               ORDER BY evolution_pct DESC
           ) AS rang
    FROM evolution
)
SELECT zone, pays, ca_2024, ca_2025, evolution_pct
FROM classement
WHERE rang = 1
ORDER BY zone;