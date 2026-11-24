-- Projet fil rouge - Ventes Nike
-- Requêtes sur le schéma en étoile

-- =============================================================================
-- Jointures, agrégats, sous-requêtes
-- =============================================================================

-- 1. Nombre de commandes et CA par ville, uniquement les villes au-delà de 500 000 $
SELECT g.ville,
       g.pays,
       COUNT(DISTINCT f.commande_id) AS nb_commandes,
       SUM(f.chiffre_affaires)       AS ca
FROM fait_ventes f
JOIN dim_geographie g ON g.geographie_id = f.geographie_id
GROUP BY g.ville, g.pays
HAVING SUM(f.chiffre_affaires) > 500000
ORDER BY ca DESC;

-- 2a. Clients qui n'ont jamais commandé (LEFT JOIN)
SELECT c.client_id, c.ville_residence, c.date_inscription
FROM dim_client c
LEFT JOIN fait_ventes f ON f.client_id = c.client_id
WHERE f.client_id IS NULL;

-- 2b. Clients qui n'ont jamais commandé (NOT EXISTS)
SELECT c.client_id, c.ville_residence, c.date_inscription
FROM dim_client c
WHERE NOT EXISTS (
    SELECT 1 FROM fait_ventes f WHERE f.client_id = c.client_id
);

-- 3. Commandes dont le montant dépasse le montant moyen d'une commande
SELECT f.commande_id, SUM(f.chiffre_affaires) AS montant_commande
FROM fait_ventes f
GROUP BY f.commande_id
HAVING SUM(f.chiffre_affaires) > (
    SELECT AVG(montant) FROM (
        SELECT SUM(chiffre_affaires) AS montant FROM fait_ventes GROUP BY commande_id
    ) AS t
)
ORDER BY montant_commande DESC;

-- 4. Liste des catégories de chaque univers (DISTINCT)
SELECT DISTINCT univers, categorie
FROM dim_produit
WHERE niveau = 'Produit'
ORDER BY univers, categorie;

-- 5. CA et bénéfices par zone et par canal de vente
SELECT g.zone,
       f.canal_vente,
       SUM(f.chiffre_affaires) AS ca,
       SUM(f.benefices)        AS benefices
FROM fait_ventes f
JOIN dim_geographie g ON g.geographie_id = f.geographie_id
GROUP BY g.zone, f.canal_vente
ORDER BY ca DESC;

-- =============================================================================
-- Fonctions de fenêtre
-- =============================================================================

-- 6. CA de chaque produit et part du CA de sa catégorie (SUM OVER PARTITION BY)
SELECT p.categorie,
       p.nom,
       SUM(f.chiffre_affaires) AS ca_produit,
       SUM(SUM(f.chiffre_affaires)) OVER (PARTITION BY p.categorie) AS ca_categorie,
       ROUND(100 * SUM(f.chiffre_affaires)
             / SUM(SUM(f.chiffre_affaires)) OVER (PARTITION BY p.categorie), 1) AS part_pct
FROM fait_ventes f
JOIN dim_produit p ON p.produit_id = f.produit_id
GROUP BY p.categorie, p.nom
ORDER BY p.categorie, ca_produit DESC;

-- 7. Top 3 des produits par catégorie (RANK)
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

-- 8. Évolution du CA mensuel en % par rapport au mois précédent (LAG)
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

-- 9. Segmentation des clients en quartiles de CA (NTILE)
WITH ca_client AS (
    SELECT client_id, SUM(chiffre_affaires) AS ca
    FROM fait_ventes
    GROUP BY client_id
)
SELECT client_id,
       ca,
       NTILE(4) OVER (ORDER BY ca DESC) AS quartile   -- 1 = les 25 % de clients qui dépensent le plus
FROM ca_client
ORDER BY ca DESC;

-- 10. Délai moyen (en jours) entre deux commandes d'un même client (LAG)
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

-- 11. CA cumulé depuis le début de l'année, mois par mois
SELECT d.annee,
       d.mois,
       SUM(f.chiffre_affaires) AS ca_mois,
       SUM(SUM(f.chiffre_affaires)) OVER (PARTITION BY d.annee ORDER BY d.mois) AS ca_cumule
FROM fait_ventes f
JOIN dim_date d ON d.date_id = f.date_id
GROUP BY d.annee, d.mois
ORDER BY d.annee, d.mois;

-- =============================================================================
-- CTE récursive
-- =============================================================================

-- 12. Chemin complet de chaque produit dans le catalogue (Nike > univers > catégorie > produit)
WITH RECURSIVE arbre AS (
    -- 1. ancre : la racine
    SELECT produit_id, nom, niveau, parent_id,
           0 AS profondeur,
           nom::text AS chemin
    FROM dim_produit
    WHERE parent_id IS NULL
    UNION ALL
    -- 2. partie récursive : les enfants de chaque ligne trouvée
    SELECT p.produit_id, p.nom, p.niveau, p.parent_id,
           a.profondeur + 1,
           a.chemin || ' > ' || p.nom
    FROM dim_produit p
    JOIN arbre a ON p.parent_id = a.produit_id
    WHERE a.profondeur < 10                              -- 3. garde-fou
)
SELECT chemin, profondeur
FROM arbre
ORDER BY chemin;

-- 13. CA de chaque produit avec son chemin dans le catalogue
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
