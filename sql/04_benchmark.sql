-- Requête 1 : achats d'un client (filtre sur client_id)
EXPLAIN ANALYZE
SELECT d.date_complete, p.nom, f.quantite_vendue, f.chiffre_affaires
FROM fait_ventes f
JOIN dim_date d ON d.date_id = f.date_id
JOIN dim_produit p ON p.produit_id = f.produit_id
WHERE f.client_id = 4242
ORDER BY d.date_complete;

-- Requête 2 : CA par pays pendant la semaine du Black Friday 2024 (filtre sur date_id)
EXPLAIN ANALYZE
SELECT g.pays, SUM(f.chiffre_affaires) AS ca, COUNT(DISTINCT f.commande_id) AS nb_commandes
FROM fait_ventes f
JOIN dim_geographie g ON g.geographie_id = f.geographie_id
WHERE f.date_id BETWEEN 20241125 AND 20241201
GROUP BY g.pays
ORDER BY ca DESC;

-- Requête 3 : CA mensuel de l'Air Force 1 en France (filtre sur produit_id)
EXPLAIN ANALYZE
SELECT d.annee, d.mois, SUM(f.chiffre_affaires) AS ca
FROM fait_ventes f
JOIN dim_date d ON d.date_id = f.date_id
JOIN dim_geographie g ON g.geographie_id = f.geographie_id
WHERE f.produit_id = 120 AND g.pays = 'France'
GROUP BY d.annee, d.mois
ORDER BY d.annee, d.mois;
