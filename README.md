# Projet fil rouge – Ventes Nike

Analyse des ventes Nike dans le monde entre juillet 2023 et juillet 2025 (PostgreSQL).

**Question métier :** quels produits, quels marchés et quel canal de vente rapportent le plus à Nike, et comment les ventes évoluent-elles au fil des mois ?

## Données

- Source : [Nike Sales Dataset – Kaggle](https://www.kaggle.com/datasets/nayakganesh007/nike-sales-uncleaned-dataset), licence CC0, données fictives (2 500 commandes en Inde).
- Nous avons nettoyé ce fichier puis ajouté des commandes sur les autres marchés de Nike. La répartition suit les résultats publiés par Nike pour l'exercice 2025 (North America ~44 %, EMEA ~27 %, Greater China ~15 %, APLA ~14 %).
- Les montants sont en dollars (USD).
- Dans `commandes`, `order_id_source` est renseigné pour les commandes venant du fichier Kaggle et vide pour les commandes ajoutées.

## Contenu du dépôt

| Dossier / fichier | Contenu |
|---|---|
| `sql/creation_tables.sql` | Création des 8 tables (PK, FK, contraintes) et import des CSV |
| `sql/requetes.sql` | Requêtes de jointure et d'agrégat |
| `data/` | Données au format CSV |
| `source_kaggle/` | Commandes Kaggle nettoyées, utilisées par le script de génération |
| `generer_donnees.py` | Script qui génère les données de `data/` |
| `docs/schema_relationnel.png` | Schéma relationnel |

## Créer la base

```bash
createdb nike
psql -d nike -f sql/creation_tables.sql
```

## Générer plus de données (tests de performance)

```bash
pip install pandas numpy
python generer_donnees.py --commandes 6900000 --out data_10M   # environ 10 millions de lignes
```

Le dossier `data_10M/` n'est pas envoyé sur GitHub (fichiers trop lourds). Pour charger ces données, remplacer `data/` par `data_10M/` dans `sql/creation_tables.sql`.
