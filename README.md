# Projet fil rouge – Ventes Nike

Groupe : Ashley Waynell Tagne Negueko, Saïdou Coumaré, Eli Moktar, Michel Guy

Module Ingénierie des données & pipelines SQL – M1 Data Engineering, Ynov.

## Sujet

On analyse les ventes Nike dans le monde entre 2023 et 2025.

Question métier : quels produits, quels marchés et quel canal de vente (en ligne ou en magasin) rapportent le plus à Nike, et comment les ventes évoluent au fil des mois ?

## Données

- Source : [Nike Sales Dataset – Kaggle](https://www.kaggle.com/datasets/nayakganesh007/nike-sales-uncleaned-dataset)
- Licence : CC0 (domaine public), données fictives

Le fichier de départ était sale (dates dans plusieurs formats, doublons, valeurs manquantes). On l'a nettoyé et découpé en 5 tables, qui sont dans `data/`. Les montants sont en dollars.

## Contenu du dépôt

- `sql/00_creation_schema.sql` : création des tables (clés, contraintes) et chargement des CSV
- `sql/01_generation_volume.sql` : passage à environ 10 millions de ventes
- `sql/02_requetes_avancees.sql` : requêtes avancées (fenêtres, CTE, WITH RECURSIVE)
- `sql/03_index.sql` : index utilisés pour le benchmark
- `sql/04_benchmark.sql` : les 3 requêtes mesurées avec EXPLAIN ANALYZE
- `docs/rapport_performance.md` : résultats avant / après index
- `docs/schema.png` : schéma de la base
- `projet_fil_rouge/` : projet dbt (staging, intermediate, marts, tests)

## Lancer le projet

Base PostgreSQL `nike`, à lancer depuis la racine du dépôt :

```bash
psql -d nike -f sql/00_creation_schema.sql
psql -d nike -f sql/01_generation_volume.sql
psql -d nike -f sql/03_index.sql
```

Puis dbt (il faut un profil `projet_fil_rouge` dans `~/.dbt/profiles.yml`) :

```bash
cd projet_fil_rouge
dbt build
dbt docs generate
dbt docs serve
```

Les tables brutes sont dans le schéma `public`, ce que crée dbt est dans `analytics`.
