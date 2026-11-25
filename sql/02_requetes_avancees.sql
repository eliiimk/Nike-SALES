<<<<<<< HEAD
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
=======
SELECT g.ville,
       g.pays,
       COUNT(DISTINCT f.commande_id) AS nb_commandes,
       SUM(f.chiffre_affaires)       AS ca
FROM fait_ventes f
JOIN dim_geographie g ON g.geographie_id = f.geographie_id
GROUP BY g.ville, g.pays
HAVING SUM(f.chiffre_affaires) > 500000
ORDER BY ca DESC;

SELECT c.client_id, c.ville_residence, c.date_inscription
FROM dim_client c
LEFT JOIN fait_ventes f ON f.client_id = c.client_id
WHERE f.client_id IS NULL;

SELECT c.client_id, c.ville_residence, c.date_inscription
FROM dim_client c
WHERE NOT EXISTS (
    SELECT 1 FROM fait_ventes f WHERE f.client_id = c.client_id
);

SELECT f.commande_id, SUM(f.chiffre_affaires) AS montant_commande
FROM fait_ventes f
GROUP BY f.commande_id
HAVING SUM(f.chiffre_affaires) > (
    SELECT AVG(montant) FROM (
        SELECT SUM(chiffre_affaires) AS montant FROM fait_ventes GROUP BY commande_id
    ) AS t
)
ORDER BY montant_commande DESC;

SELECT g.zone,
       f.canal_vente,
       SUM(f.chiffre_affaires) AS ca,
       SUM(f.benefices)        AS benefices
FROM fait_ventes f
JOIN dim_geographie g ON g.geographie_id = f.geographie_id
GROUP BY g.zone, f.canal_vente
ORDER BY ca DESC;

WITH ventes_produit AS (
    SELECT p.categorie, p.nom, SUM(f.chiffre_affaires) AS ca
    FROM fait_ventes f
    JOIN dim_produit p ON p.produit_id = f.produit_id
    GROUP BY p.categorie, p.nom
),
classement AS (
    SELECT *, RANK() OVER (PARTITION BY categorie ORDER BY ca DESC) AS rang
    FROM ventes_produit
)
SELECT categorie, nom, ca, rang
FROM classement
WHERE rang <= 3
ORDER BY categorie, rang;

SELECT p.categorie,
       p.nom,
       SUM(f.chiffre_affaires) AS ca_produit,
       ROUND(100 * SUM(f.chiffre_affaires)
             / SUM(SUM(f.chiffre_affaires)) OVER (PARTITION BY p.categorie), 1) AS part_pct
FROM fait_ventes f
JOIN dim_produit p ON p.produit_id = f.produit_id
GROUP BY p.categorie, p.nom
ORDER BY p.categorie, ca_produit DESC;

WITH ca_mois AS (
    SELECT d.annee, d.mois, SUM(f.chiffre_affaires) AS ca
    FROM fait_ventes f
    JOIN dim_date d ON d.date_id = f.date_id
    GROUP BY d.annee, d.mois
)
SELECT annee,
       mois,
       ca,
       LAG(ca) OVER (ORDER BY annee, mois) AS ca_mois_precedent,
       ROUND(100 * (ca - LAG(ca) OVER (ORDER BY annee, mois))
             / LAG(ca) OVER (ORDER BY annee, mois), 1) AS evolution_pct
FROM ca_mois
ORDER BY annee, mois;

WITH commandes AS (
    SELECT DISTINCT f.client_id, f.commande_id, d.date_complete
    FROM fait_ventes f
    JOIN dim_date d ON d.date_id = f.date_id
),
ecarts AS (
    SELECT client_id,
           date_complete - LAG(date_complete) OVER (PARTITION BY client_id ORDER BY date_complete) AS jours
    FROM commandes
)
SELECT ROUND(AVG(jours), 1) AS delai_moyen_jours
FROM ecarts
WHERE jours IS NOT NULL;

WITH ca_client AS (
    SELECT client_id, SUM(chiffre_affaires) AS ca
    FROM fait_ventes
    GROUP BY client_id
)
SELECT client_id,
       ca,
       NTILE(4) OVER (ORDER BY ca DESC) AS quartile
FROM ca_client
ORDER BY ca DESC;

WITH ca_jour AS (
    SELECT d.date_complete, SUM(f.chiffre_affaires) AS ca
    FROM fait_ventes f
    JOIN dim_date d ON d.date_id = f.date_id
    GROUP BY d.date_complete
)
SELECT date_complete,
       ca,
       ROUND(AVG(ca) OVER (ORDER BY date_complete ROWS BETWEEN 6 PRECEDING AND CURRENT ROW), 2) AS moyenne_7_jours
FROM ca_jour
ORDER BY date_complete;

SELECT d.annee,
       d.mois,
       SUM(f.chiffre_affaires) AS ca_mois,
       SUM(SUM(f.chiffre_affaires)) OVER (PARTITION BY d.annee ORDER BY d.mois
                                          ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS ca_cumule
FROM fait_ventes f
JOIN dim_date d ON d.date_id = f.date_id
GROUP BY d.annee, d.mois
ORDER BY d.annee, d.mois;

WITH RECURSIVE arbre AS (
    SELECT produit_id, nom, niveau, parent_id,
           0 AS profondeur,
           nom::text AS chemin
    FROM dim_produit
    WHERE parent_id IS NULL
    UNION ALL
    SELECT p.produit_id, p.nom, p.niveau, p.parent_id,
           a.profondeur + 1,
           a.chemin || ' > ' || p.nom
    FROM dim_produit p
    JOIN arbre a ON p.parent_id = a.produit_id
    WHERE a.profondeur < 10
)
SELECT chemin, profondeur
FROM arbre
ORDER BY chemin;


WITH RECURSIVE arbre AS (
    SELECT produit_id, nom, niveau, nom::text AS chemin
    FROM dim_produit
    WHERE parent_id IS NULL
    UNION ALL
    SELECT p.produit_id, p.nom, p.niveau, a.chemin || ' > ' || p.nom
    FROM dim_produit p
    JOIN arbre a ON p.parent_id = a.produit_id
)
SELECT a.chemin, SUM(f.chiffre_affaires) AS ca
FROM arbre a
JOIN fait_ventes f ON f.produit_id = a.produit_id
WHERE a.niveau = 'Produit'
GROUP BY a.chemin
ORDER BY ca DESC;
>>>>>>> origin/blanche-eli

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
<<<<<<< HEAD
ORDER BY zone;
=======
ORDER BY zone;
=======

-- Top 3 des produits par catégorie selon le chiffre d'affaires

WITH ca_par_produit AS (
    SELECT
        dp.categorie,
        dp.produit_id,
        dp.nom_produit,
        SUM(fv.chiffre_affaires) AS ca_total
    FROM fait_ventes fv
    JOIN dim_produit dp
        ON dp.produit_id = fv.produit_id
    GROUP BY
        dp.categorie,
        dp.produit_id,
        dp.nom_produit
),
classement_produits AS (
    SELECT
        categorie,
        produit_id,
        nom_produit,
        ca_total,
        ROW_NUMBER() OVER (
            PARTITION BY categorie
            ORDER BY ca_total DESC
        ) AS rang
    FROM ca_par_produit
)
SELECT
    categorie,
    rang,
    nom_produit,
    ca_total
FROM classement_produits
WHERE rang <= 3
ORDER BY categorie, rang;


-- Afficher le chemin complet de chaque catégorie

WITH RECURSIVE chemin_categories AS (
    -- Cas de base : catégories racines
    SELECT
        c.categorie_id,
        c.nom_categorie,
        c.categorie_parent_id,
        c.niveau,
        c.nom_categorie::TEXT AS chemin_complet
    FROM categories c
    WHERE c.categorie_parent_id IS NULL

    UNION ALL

    -- Récursion : sous-catégories rattachées à leur parent
    SELECT
        c.categorie_id,
        c.nom_categorie,
        c.categorie_parent_id,
        c.niveau,
        (cc.chemin_complet || ' > ' || c.nom_categorie)::TEXT AS chemin_complet
    FROM categories c
    JOIN chemin_categories cc
        ON c.categorie_parent_id = cc.categorie_id
)
SELECT
    categorie_id,
    nom_categorie,
    niveau,
    chemin_complet
FROM chemin_categories
ORDER BY chemin_complet;
>>>>>>> origin/blanche-eli
