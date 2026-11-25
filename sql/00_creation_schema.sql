DROP TABLE IF EXISTS fait_ventes, dim_date, dim_client, dim_produit, dim_geographie;

CREATE TABLE dim_date (
    date_id       INTEGER PRIMARY KEY,
    date_complete DATE NOT NULL UNIQUE,
    annee         SMALLINT NOT NULL,
    trimestre     SMALLINT NOT NULL CHECK (trimestre BETWEEN 1 AND 4),
    mois          SMALLINT NOT NULL CHECK (mois BETWEEN 1 AND 12),
    nom_mois      VARCHAR(10) NOT NULL,
    semaine       SMALLINT NOT NULL,
    jour_semaine  SMALLINT NOT NULL CHECK (jour_semaine BETWEEN 1 AND 7),
    nom_jour      VARCHAR(10) NOT NULL,
    est_weekend   BOOLEAN NOT NULL
);

CREATE TABLE dim_client (
    client_id        INTEGER PRIMARY KEY,
    sexe             CHAR(1) NOT NULL CHECK (sexe IN ('H', 'F')),
    tranche_age      VARCHAR(5) NOT NULL,
    ville_residence  VARCHAR(50) NOT NULL,
    pays_residence   VARCHAR(50) NOT NULL,
    membre_nike      BOOLEAN NOT NULL,
    date_inscription DATE NOT NULL
);

CREATE TABLE dim_produit (
    produit_id     INTEGER PRIMARY KEY,
    nom            VARCHAR(100) NOT NULL UNIQUE,
    niveau         VARCHAR(20) NOT NULL CHECK (niveau IN ('Marque', 'Univers', 'Catégorie', 'Produit')),
    parent_id      INTEGER REFERENCES dim_produit (produit_id),
    categorie      VARCHAR(50),
    univers        VARCHAR(50),
    prix_catalogue NUMERIC(10, 2) CHECK (prix_catalogue > 0)
);

CREATE TABLE dim_geographie (
    geographie_id INTEGER PRIMARY KEY,
    ville         VARCHAR(50) NOT NULL UNIQUE,
    pays          VARCHAR(50) NOT NULL,
    zone          VARCHAR(50) NOT NULL
);

CREATE TABLE fait_ventes (
    vente_id         INTEGER PRIMARY KEY,
    commande_id      INTEGER NOT NULL,
    order_id_source  INTEGER,
    date_id          INTEGER NOT NULL REFERENCES dim_date (date_id),
    client_id        INTEGER NOT NULL REFERENCES dim_client (client_id),
    produit_id       INTEGER NOT NULL REFERENCES dim_produit (produit_id),
    geographie_id    INTEGER NOT NULL REFERENCES dim_geographie (geographie_id),
    canal_vente      VARCHAR(10) NOT NULL CHECK (canal_vente IN ('Online', 'Retail')),
    genre_cible      VARCHAR(10) NOT NULL CHECK (genre_cible IN ('Men', 'Women', 'Kids')),
    taille           VARCHAR(5) NOT NULL,
    quantite_vendue  INTEGER NOT NULL CHECK (quantite_vendue > 0),
    prix_unitaire    NUMERIC(10, 2) NOT NULL CHECK (prix_unitaire > 0),
    remise           NUMERIC(4, 2) NOT NULL DEFAULT 0 CHECK (remise BETWEEN 0 AND 1),
    chiffre_affaires NUMERIC(12, 2) NOT NULL CHECK (chiffre_affaires >= 0),
    benefices        NUMERIC(12, 2) NOT NULL
);

\copy dim_date       FROM 'data/dim_date.csv'       WITH (FORMAT csv, HEADER true)
\copy dim_client     FROM 'data/dim_client.csv'     WITH (FORMAT csv, HEADER true)
\copy dim_produit    FROM 'data/dim_produit.csv'    WITH (FORMAT csv, HEADER true)
\copy dim_geographie FROM 'data/dim_geographie.csv' WITH (FORMAT csv, HEADER true)
\copy fait_ventes    FROM 'data/fait_ventes.csv'    WITH (FORMAT csv, HEADER true)
