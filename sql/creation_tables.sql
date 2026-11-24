-- Projet fil rouge - Ventes Nike
-- Création des tables et import des données (PostgreSQL)

DROP TABLE IF EXISTS lignes_commande, commandes, produits, categories_produits, univers, regions;

CREATE TABLE regions (
    region_id   INTEGER PRIMARY KEY,
    region_nom  VARCHAR(50) NOT NULL UNIQUE
);

CREATE TABLE univers (
    univers_id  INTEGER PRIMARY KEY,
    nom_univers VARCHAR(50) NOT NULL UNIQUE
);

CREATE TABLE categories_produits (
    categorie_id  INTEGER PRIMARY KEY,
    nom_categorie VARCHAR(50) NOT NULL UNIQUE,
    univers_id    INTEGER NOT NULL REFERENCES univers (univers_id)
);

CREATE TABLE produits (
    produit_id     INTEGER PRIMARY KEY,
    nom_produit    VARCHAR(100) NOT NULL UNIQUE,
    categorie_id   INTEGER NOT NULL REFERENCES categories_produits (categorie_id),
    prix_catalogue NUMERIC(10, 2) NOT NULL CHECK (prix_catalogue > 0)
);

CREATE TABLE commandes (
    commande_id     INTEGER PRIMARY KEY,
    order_id_source INTEGER NOT NULL,
    date_commande   DATE NOT NULL,
    canal_vente     VARCHAR(10) NOT NULL CHECK (canal_vente IN ('Online', 'Retail')),
    region_id       INTEGER NOT NULL REFERENCES regions (region_id)
);

CREATE TABLE lignes_commande (
    ligne_id         INTEGER PRIMARY KEY,
    commande_id      INTEGER NOT NULL REFERENCES commandes (commande_id),
    produit_id       INTEGER NOT NULL REFERENCES produits (produit_id),
    genre_cible      VARCHAR(10) NOT NULL CHECK (genre_cible IN ('Men', 'Women', 'Kids')),
    taille           VARCHAR(5) NOT NULL,
    quantite_vendue  INTEGER NOT NULL CHECK (quantite_vendue > 0),
    prix_unitaire    NUMERIC(10, 2) NOT NULL CHECK (prix_unitaire > 0),
    remise           NUMERIC(4, 2) NOT NULL DEFAULT 0 CHECK (remise BETWEEN 0 AND 1),
    chiffre_affaires NUMERIC(12, 2) NOT NULL,
    benefices        NUMERIC(12, 2) NOT NULL
);

\copy regions             FROM 'data/regions.csv'             WITH (FORMAT csv, HEADER true)
\copy univers             FROM 'data/univers.csv'             WITH (FORMAT csv, HEADER true)
\copy categories_produits FROM 'data/categories_produits.csv' WITH (FORMAT csv, HEADER true)
\copy produits            FROM 'data/produits.csv'            WITH (FORMAT csv, HEADER true)
\copy commandes           FROM 'data/commandes.csv'           WITH (FORMAT csv, HEADER true)
\copy lignes_commande     FROM 'data/lignes_commande.csv'     WITH (FORMAT csv, HEADER true)
