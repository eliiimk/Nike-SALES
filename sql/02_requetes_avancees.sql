-- 1. Quelles villes dépassent 500 000 $ de chiffre d'affaires ?
SELECT g.ville,
       g.pays,
       COUNT(DISTINCT f.commande_id) AS nb_commandes,
       SUM(f.chiffre_affaires)       AS ca
FROM fait_ventes f
JOIN dim_geographie g ON g.geographie_id = f.geographie_id
GROUP BY g.ville, g.pays
HAVING SUM(f.chiffre_affaires) > 500000
ORDER BY ca DESC;

-- 2. Quels clients n'ont jamais acheté ? (LEFT JOIN)
SELECT c.client_id, c.ville_residence, c.date_inscription
FROM dim_client c
LEFT JOIN fait_ventes f ON f.client_id = c.client_id
WHERE f.client_id IS NULL;

-- 3. Même question avec NOT EXISTS
SELECT c.client_id, c.ville_residence, c.date_inscription
FROM dim_client c
WHERE NOT EXISTS (
    SELECT 1 FROM fait_ventes f WHERE f.client_id = c.client_id
);

-- 4. Quelles commandes dépassent le montant moyen d'une commande ?
SELECT f.commande_id, SUM(f.chiffre_affaires) AS montant_commande
FROM fait_ventes f
GROUP BY f.commande_id
HAVING SUM(f.chiffre_affaires) > (
    SELECT AVG(montant) FROM (
        SELECT SUM(chiffre_affaires) AS montant FROM fait_ventes GROUP BY commande_id
    ) AS t
)
ORDER BY montant_commande DESC;

-- 5. Quel CA et quel bénéfice par zone et par canal de vente ?
SELECT g.zone,
       f.canal_vente,
       SUM(f.chiffre_affaires) AS ca,
       SUM(f.benefices)        AS benefices
FROM fait_ventes f
JOIN dim_geographie g ON g.geographie_id = f.geographie_id
GROUP BY g.zone, f.canal_vente
ORDER BY ca DESC;

-- 6. Quels sont les 3 produits qui rapportent le plus dans chaque catégorie ? (RANK)
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

-- 7. Quelle part du CA de sa catégorie fait chaque produit ?
SELECT p.categorie,
       p.nom,
       SUM(f.chiffre_affaires) AS ca_produit,
       ROUND(100 * SUM(f.chiffre_affaires)
             / SUM(SUM(f.chiffre_affaires)) OVER (PARTITION BY p.categorie), 1) AS part_pct
FROM fait_ventes f
JOIN dim_produit p ON p.produit_id = f.produit_id
GROUP BY p.categorie, p.nom
ORDER BY p.categorie, ca_produit DESC;

-- 8. Comment évolue le CA d'un mois à l'autre, en % ?
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

-- 9. Combien de jours en moyenne entre deux commandes d'un même client ?
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

-- 10. Comment se répartissent les clients en 4 groupes de CA ? (quartiles)
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

-- 11. Quelle est la tendance du CA jour par jour ? (moyenne sur 7 jours)
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

-- 12. Quel CA cumulé depuis le début de l'année, mois après mois ?
SELECT d.annee,
       d.mois,
       SUM(f.chiffre_affaires) AS ca_mois,
       SUM(SUM(f.chiffre_affaires)) OVER (PARTITION BY d.annee ORDER BY d.mois
                                          ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS ca_cumule
FROM fait_ventes f
JOIN dim_date d ON d.date_id = f.date_id
GROUP BY d.annee, d.mois
ORDER BY d.annee, d.mois;

-- 13. Quel est le chemin de chaque élément dans la hiérarchie produit ?
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

-- 14. Quel CA pour chaque produit, avec sa place dans la hiérarchie ?
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

-- 15. Dans chaque zone, quel pays a le plus progressé entre le 1er semestre 2024 et 2025 ?
WITH ventes_semestre AS (
    SELECT g.zone, g.pays, d.annee, f.chiffre_affaires
    FROM fait_ventes f
    JOIN dim_date d       ON d.date_id       = f.date_id
    JOIN dim_geographie g ON g.geographie_id = f.geographie_id
    WHERE d.mois BETWEEN 1 AND 6
      AND d.annee IN (2024, 2025)
),
ca_pays AS (
    SELECT zone, pays,
           SUM(CASE WHEN annee = 2024 THEN chiffre_affaires ELSE 0 END) AS ca_2024,
           SUM(CASE WHEN annee = 2025 THEN chiffre_affaires ELSE 0 END) AS ca_2025
    FROM ventes_semestre
    GROUP BY zone, pays
),
evolution AS (
    SELECT *, ROUND(100 * (ca_2025 - ca_2024) / ca_2024, 1) AS evolution_pct
    FROM ca_pays
),
classement AS (
    SELECT *, RANK() OVER (PARTITION BY zone ORDER BY evolution_pct DESC) AS rang
    FROM evolution
)
SELECT zone, pays, ca_2024, ca_2025, evolution_pct
FROM classement
WHERE rang = 1
ORDER BY zone;

-- 16. Un client achète-t-il plus ou moins que lors de son achat précédent ?
SELECT
    client_id,
    date_id,
    quantite_vendue,
    LAG(quantite_vendue) OVER (
        PARTITION BY client_id
        ORDER BY date_id
    ) AS quantite_precedente
FROM fait_ventes;

-- 17. Top 3 des produits par catégorie selon le CA (ROW_NUMBER)
WITH ca_par_produit AS (
    SELECT
        dp.categorie,
        dp.produit_id,
        dp.nom,
        SUM(fv.chiffre_affaires) AS ca_total
    FROM fait_ventes fv
    JOIN dim_produit dp
        ON dp.produit_id = fv.produit_id
    GROUP BY
        dp.categorie,
        dp.produit_id,
        dp.nom
),
classement_produits AS (
    SELECT
        categorie,
        produit_id,
        nom,
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
    nom,
    ca_total
FROM classement_produits
WHERE rang <= 3
ORDER BY categorie, rang;

-- 18. Quel est le chemin complet de chaque catégorie, sans les produits ?
WITH RECURSIVE chemin_categories AS (
    SELECT
        p.produit_id,
        p.nom,
        p.parent_id,
        p.niveau,
        p.nom::TEXT AS chemin_complet
    FROM dim_produit p
    WHERE p.parent_id IS NULL

    UNION ALL

    SELECT
        p.produit_id,
        p.nom,
        p.parent_id,
        p.niveau,
        (cc.chemin_complet || ' > ' || p.nom)::TEXT AS chemin_complet
    FROM dim_produit p
    JOIN chemin_categories cc
        ON p.parent_id = cc.produit_id
)
SELECT
    produit_id,
    nom,
    niveau,
    chemin_complet
FROM chemin_categories
WHERE niveau <> 'Produit'
ORDER BY chemin_complet;

-- 19. Comment se répartissent les commandes en 4 groupes de CA ? (quartiles)
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
