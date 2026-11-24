-- 1. CA et bénéfices par région et par canal de vente
SELECT r.region_nom,
       c.canal_vente,
       COUNT(DISTINCT c.commande_id) AS nb_commandes,
       SUM(l.chiffre_affaires)       AS ca_total,
       SUM(l.benefices)              AS benefices_total
FROM lignes_commande l
JOIN commandes c ON c.commande_id = l.commande_id
JOIN regions r   ON r.region_id   = c.region_id
GROUP BY r.region_nom, c.canal_vente
ORDER BY ca_total DESC;

-- 2. Catégories qui ont vendu plus de 1 200 unités, avec la remise moyenne
SELECT cat.nom_categorie,
       SUM(l.quantite_vendue)          AS unites_vendues,
       ROUND(AVG(l.remise) * 100, 1)   AS remise_moyenne_pct,
       SUM(l.chiffre_affaires)         AS ca_total
FROM lignes_commande l
JOIN produits p              ON p.produit_id     = l.produit_id
JOIN categories_produits cat ON cat.categorie_id = p.categorie_id
GROUP BY cat.nom_categorie
HAVING SUM(l.quantite_vendue) > 1200
ORDER BY ca_total DESC;

-- 3. CA et panier moyen par mois
SELECT DATE_TRUNC('month', c.date_commande)::date AS mois,
       COUNT(DISTINCT c.commande_id)              AS nb_commandes,
       SUM(l.chiffre_affaires)                    AS ca_mensuel,
       ROUND(SUM(l.chiffre_affaires) / COUNT(DISTINCT c.commande_id), 2) AS panier_moyen
FROM commandes c
JOIN lignes_commande l ON l.commande_id = c.commande_id
GROUP BY DATE_TRUNC('month', c.date_commande)
ORDER BY mois;
