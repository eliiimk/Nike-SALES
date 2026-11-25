# Rapport de performance

Base : 10 035 984 lignes dans fait_ventes, PostgreSQL.
Temps = médiane de 3 exécutions avec EXPLAIN ANALYZE.

## Résultats

| Requête | Avant (ms) | Opérateur avant | Action | Après (ms) | Opérateur après | Gain |
| --- | --- | --- | --- | --- | --- | --- |
| Achats d'un client | 149,2 | Parallel Seq Scan | INDEX (client_id) | 0,29 | Index Scan | × 500 |
| CA par pays pendant le Black Friday 2024 | 189,2 | Parallel Seq Scan | INDEX (date_id) | 111,5 | Bitmap Index Scan | - 41 % |
| CA mensuel de l'Air Force 1 en France | 196,0 | Parallel Seq Scan | INDEX (produit_id) | 179,0 | Parallel Seq Scan | aucun |

## Requête 1 : achats d'un client

```sql
SELECT d.date_complete, p.nom, f.quantite_vendue, f.chiffre_affaires
FROM fait_ventes f
JOIN dim_date d ON d.date_id = f.date_id
JOIN dim_produit p ON p.produit_id = f.produit_id
WHERE f.client_id = 4242
ORDER BY d.date_complete;
```

Avant : `Parallel Seq Scan on fait_ventes`, toute la table est lue pour trouver le client.

Après : `Index Scan using idx_ventes_client on fait_ventes (rows=3)`

Le client n'a que 3 lignes sur 10 millions. Avec l'index sur client_id, PostgreSQL va directement sur ces 3 lignes au lieu de lire toute la table.

## Requête 2 : CA par pays pendant le Black Friday 2024

```sql
SELECT g.pays, SUM(f.chiffre_affaires) AS ca, COUNT(DISTINCT f.commande_id) AS nb_commandes
FROM fait_ventes f
JOIN dim_geographie g ON g.geographie_id = f.geographie_id
WHERE f.date_id BETWEEN 20241125 AND 20241201
GROUP BY g.pays
ORDER BY ca DESC;
```

Avant : `Parallel Seq Scan on fait_ventes`

Après : `Bitmap Index Scan on idx_ventes_date (rows=132319)` puis `Parallel Bitmap Heap Scan on fait_ventes`

L'index sur date_id est utilisé, mais la semaine contient environ 132 000 lignes (1,3 % de la table). Il faut quand même lire et additionner toutes ces lignes, donc le gain est moins important que pour la requête 1.

## Requête 3 : CA mensuel de l'Air Force 1 en France

```sql
SELECT d.annee, d.mois, SUM(f.chiffre_affaires) AS ca
FROM fait_ventes f
JOIN dim_date d ON d.date_id = f.date_id
JOIN dim_geographie g ON g.geographie_id = f.geographie_id
WHERE f.produit_id = 120 AND g.pays = 'France'
GROUP BY d.annee, d.mois
ORDER BY d.annee, d.mois;
```

Avant : `Parallel Seq Scan on fait_ventes`

Après : `Parallel Seq Scan on fait_ventes (rows=445899, loops=3)`

L'index sur produit_id n'est pas utilisé. L'Air Force 1 représente environ 1,3 million de lignes (13 % de la table). Avec autant de lignes, PostgreSQL considère que lire toute la table est plus rapide que passer par l'index. La petite différence de temps vient de la variation entre les mesures, pas de l'index.
