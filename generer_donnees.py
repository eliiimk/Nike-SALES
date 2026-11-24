"""
Génère les données du projet fil rouge (ventes Nike, données fictives) en schéma en étoile.

Table de faits : fait_ventes (une ligne = un produit vendu dans une commande)
Dimensions     : dim_date, dim_client, dim_produit, dim_geographie
Table annexe   : categories (hiérarchie catalogue, pour la CTE récursive)

- Les 2 500 commandes du dataset Kaggle (Inde, nettoyées) sont conservées (order_id_source renseigné).
- Des commandes sont ajoutées sur les autres marchés de Nike, avec une répartition proche des
  résultats de l'exercice 2025 (North America 44 %, EMEA 27 %, Greater China 15 %, APLA 14 %).
- Tous les montants sont en dollars (USD).

Usage :
    python generer_donnees.py                       # 100 000 commandes ajoutées (~150 000 ventes)
    python generer_donnees.py --commandes 6900000 --out data_10M   # ~10 millions de ventes
"""
import argparse
import os

import numpy as np
import pandas as pd

DATE_MIN = pd.Timestamp("2023-07-26")
DATE_MAX = pd.Timestamp("2025-07-22")

# Zones Nike et part du CA (exercice 2025)
ZONES = [(1, "North America", 0.44), (2, "EMEA", 0.27), (3, "Greater China", 0.15), (4, "APLA", 0.14)]

# pays : (nom, zone, poids dans la zone, indice de prix, part du web, villes avec poids)
PAYS = [
    ("États-Unis", 1, 0.88, 1.00, 0.33, [("New York", 4), ("Los Angeles", 3), ("Chicago", 2), ("Houston", 1.5), ("Miami", 1.5)]),
    ("Canada", 1, 0.12, 0.95, 0.30, [("Toronto", 3), ("Montréal", 2), ("Vancouver", 1.5)]),
    ("Royaume-Uni", 2, 0.22, 1.05, 0.35, [("Londres", 4), ("Manchester", 1.5)]),
    ("Allemagne", 2, 0.20, 1.08, 0.33, [("Berlin", 2), ("Munich", 1.5), ("Hambourg", 1.2)]),
    ("France", 2, 0.18, 1.08, 0.30, [("Paris", 4), ("Lyon", 1.3), ("Marseille", 1.2), ("Toulouse", 1)]),
    ("Espagne", 2, 0.10, 1.05, 0.25, [("Madrid", 2), ("Barcelone", 2)]),
    ("Italie", 2, 0.10, 1.08, 0.22, [("Milan", 2), ("Rome", 2)]),
    ("Pays-Bas", 2, 0.07, 1.08, 0.40, [("Amsterdam", 2), ("Rotterdam", 1)]),
    ("Émirats arabes unis", 2, 0.06, 1.10, 0.25, [("Dubaï", 3), ("Abou Dabi", 1)]),
    ("Afrique du Sud", 2, 0.07, 0.90, 0.15, [("Johannesburg", 2), ("Le Cap", 1.5)]),
    ("Chine", 3, 1.00, 0.95, 0.38, [("Shanghai", 3), ("Pékin", 2.8), ("Shenzhen", 2.2), ("Canton", 2)]),
    ("Japon", 4, 0.30, 0.90, 0.30, [("Tokyo", 3), ("Osaka", 1.5)]),
    ("Corée du Sud", 4, 0.17, 0.95, 0.40, [("Séoul", 3), ("Busan", 1)]),
    ("Australie", 4, 0.15, 0.92, 0.30, [("Sydney", 2), ("Melbourne", 2)]),
    ("Mexique", 4, 0.12, 0.95, 0.18, [("Mexico", 3), ("Guadalajara", 1)]),
    ("Brésil", 4, 0.13, 1.20, 0.20, [("São Paulo", 3), ("Rio de Janeiro", 2)]),
    ("Inde", 4, 0.13, 0.85, 0.25, [("Delhi", 1), ("Mumbai", 1), ("Pune", 1), ("Bangalore", 1), ("Hyderabad", 1), ("Kolkata", 1)]),
]

UNIVERS = [(1, "Performance"), (2, "Sportswear")]
CATEGORIES = [(1, "Running", 1), (2, "Basketball", 1), (3, "Soccer", 1), (4, "Training", 1), (5, "Lifestyle", 2)]
# produit_id, nom, categorie, prix catalogue (USD), popularité
PRODUITS = [
    (101, "React Infinity", 1, 160, 1.0), (102, "Air Zoom", 1, 130, 2.2), (103, "Free RN", 1, 100, 1.0),
    (104, "Pegasus Turbo", 1, 180, 1.2), (105, "Air Jordan", 2, 180, 2.8), (106, "Kyrie Flytrap", 2, 85, 0.8),
    (107, "Zoom Freak", 2, 120, 0.9), (108, "LeBron 20", 2, 200, 1.0), (109, "Tiempo Legend", 3, 230, 0.8),
    (110, "Premier III", 3, 100, 0.6), (111, "Mercurial Superfly", 3, 285, 1.1), (112, "Phantom GT", 3, 250, 0.8),
    (113, "SuperRep Go", 4, 100, 0.6), (114, "Flex Trainer", 4, 70, 0.9), (115, "Metcon 7", 4, 130, 0.9),
    (116, "ZoomX Invincible", 4, 180, 0.8), (117, "Blazer Mid", 5, 105, 1.4), (118, "Waffle One", 5, 100, 0.8),
    (119, "Dunk Low", 5, 115, 3.0), (120, "Air Force 1", 5, 115, 3.5),
]
TAILLES = {"Men": [str(t) for t in range(7, 14)], "Women": [str(t) for t in range(5, 12)], "Kids": [str(t) for t in range(1, 8)]}


NOMS_MOIS = ["janvier", "février", "mars", "avril", "mai", "juin", "juillet", "août",
             "septembre", "octobre", "novembre", "décembre"]
NOMS_JOURS = ["lundi", "mardi", "mercredi", "jeudi", "vendredi", "samedi", "dimanche"]


# ---------------------------------------------------------------------------
# Dimensions
# ---------------------------------------------------------------------------
def dim_geographie():
    zones = {z: n for z, n, _ in ZONES}
    rows, gid = [], 1
    for nom_pays, zone, *_, villes in PAYS:
        for ville, _ in villes:
            rows.append((gid, ville, nom_pays, zones[zone]))
            gid += 1
    return pd.DataFrame(rows, columns=["geographie_id", "ville", "pays", "zone"])


def dim_produit():
    cat = {c: (n, u) for c, n, u in CATEGORIES}
    univ = dict(UNIVERS)
    return pd.DataFrame(
        [(p, nom, cat[c][0], univ[cat[c][1]], prix) for p, nom, c, prix, _ in PRODUITS],
        columns=["produit_id", "nom_produit", "categorie", "univers", "prix_catalogue"])


def table_categories():
    """Hiérarchie du catalogue : Nike > univers > catégorie > produit (auto-référence)."""
    rows = [(1, "Nike", None, "Marque")]
    ids = {}
    for u, nom in UNIVERS:
        ids[("u", u)] = 10 + u
        rows.append((10 + u, nom, 1, "Univers"))
    for c, nom, u in CATEGORIES:
        ids[("c", c)] = 100 + c
        rows.append((100 + c, nom, ids[("u", u)], "Catégorie"))
    for p, nom, c, *_ in PRODUITS:
        rows.append((1000 + p, nom, ids[("c", c)], "Produit"))
    df = pd.DataFrame(rows, columns=["categorie_id", "nom_categorie", "categorie_parent_id", "niveau"])
    df["categorie_parent_id"] = df["categorie_parent_id"].astype("Int64")
    return df


def dim_date():
    jours = pd.date_range("2023-07-01", "2025-07-31", freq="D")
    return pd.DataFrame({
        "date_id": jours.strftime("%Y%m%d").astype(int),
        "date_complete": jours.date,
        "annee": jours.year,
        "trimestre": jours.quarter,
        "mois": jours.month,
        "nom_mois": [NOMS_MOIS[m - 1] for m in jours.month],
        "semaine": jours.isocalendar().week.to_numpy(),
        "jour_semaine": jours.dayofweek + 1,
        "nom_jour": [NOMS_JOURS[d] for d in jours.dayofweek],
        "est_weekend": jours.dayofweek >= 5,
    })


def dim_client(n, geo, rng):
    """Clients rattachés à une ville de résidence. _w (fréquence d'achat) n'est pas exporté."""
    w_ville = poids_villes()
    ville = rng.choice(len(geo), n, p=w_ville)
    age = rng.choice(["18-24", "25-34", "35-44", "45-54", "55+"], n, p=[0.24, 0.31, 0.21, 0.14, 0.10])
    df = pd.DataFrame({
        "client_id": np.arange(1, n + 1),
        "sexe": rng.choice(["H", "F"], n, p=[0.55, 0.45]),
        "tranche_age": age,
        "ville_residence": geo["ville"].to_numpy()[ville],
        "pays_residence": geo["pays"].to_numpy()[ville],
        "membre_nike": rng.random(n) < 0.6,
        "date_inscription": pd.NaT,
        "_geo": geo["geographie_id"].to_numpy()[ville],
        "_w": np.minimum(rng.pareto(2.0, n) + 1, 8),
    })
    span = (DATE_MAX - DATE_MIN).days + 1500
    df["date_inscription"] = DATE_MAX - pd.to_timedelta(rng.integers(0, span, n), unit="D")
    return df


def poids_villes():
    zone_part = {z: p for z, _, p in ZONES}
    w = []
    for nom, zone, part_pays, _, _, villes in PAYS:
        tot = sum(p for _, p in villes)
        w += [zone_part[zone] * part_pays * p / tot for _, p in villes]
    w = np.array(w)
    return w / w.sum()


def poids_dates():
    jours = pd.date_range(DATE_MIN, DATE_MAX, freq="D")
    mois = jours.month.to_numpy()
    saison = np.select([mois == 11, mois == 12, np.isin(mois, [8, 9]), np.isin(mois, [1, 2])], [1.45, 1.55, 1.15, 0.85], 1.0)
    weekend = np.where(jours.dayofweek.to_numpy() >= 5, 1.2, 1.0)
    # Légère croissance jusqu'à mi-2024 puis baisse sur l'exercice 2025 (comme les résultats réels de Nike)
    t = ((jours - pd.Timestamp("2024-06-01")).days / 365).to_numpy()
    tendance = np.where(t < 0, 1 + 0.03 * t, 1 - 0.10 * t)
    w = saison * weekend * tendance
    return jours, w / w.sum()


def infos_pays(geo):
    """Indice de prix et part du web pour chaque geographie_id."""
    par_pays = {nom: (prix, web) for nom, _, _, prix, web, _ in PAYS}
    prix = geo["pays"].map(lambda p: par_pays[p][0]).to_numpy()
    web = geo["pays"].map(lambda p: par_pays[p][1]).to_numpy()
    return prix, web


def choisir_clients(geo_cmd, clients, rng):
    """Un client de la ville de la commande, les plus fidèles achetant plus souvent."""
    out = np.empty(len(geo_cmd), dtype=np.int64)
    for g, grp in clients.groupby("_geo"):
        m = geo_cmd == g
        if m.any():
            w = grp["_w"].to_numpy()
            out[m] = rng.choice(grp["client_id"].to_numpy(), m.sum(), p=w / w.sum())
    return out


# ---------------------------------------------------------------------------
# Faits
# ---------------------------------------------------------------------------
def ventes_kaggle(dossier, geo, clients, rng):
    """Commandes Kaggle nettoyées (Inde) : prix catalogue USD (indice Inde), remises plafonnées à 50 %,
    tailles converties en pointures."""
    c = pd.read_csv(os.path.join(dossier, "commandes.csv"))
    l = pd.read_csv(os.path.join(dossier, "lignes_commande.csv"))
    anciennes = pd.read_csv(os.path.join(dossier, "regions.csv"))
    ville = c["region_id"].map(dict(zip(anciennes["region_id"], anciennes["region_nom"])))
    c["geographie_id"] = ville.map(dict(zip(geo["ville"], geo["geographie_id"])))
    c["client_id"] = choisir_clients(c["geographie_id"].to_numpy(), clients, rng)
    f = l.merge(c, on="commande_id")
    prix = f["produit_id"].map({p[0]: p[3] for p in PRODUITS})
    pas_pointure = ~f["taille"].astype(str).str.isdigit()
    f.loc[pas_pointure, "taille"] = [rng.choice(TAILLES[g]) for g in f.loc[pas_pointure, "genre_cible"]]
    return pd.DataFrame({
        "commande_id": f["commande_id"],
        "order_id_source": f["order_id_source"].astype("Int64"),
        "date_id": pd.to_datetime(f["date_commande"]).dt.strftime("%Y%m%d").astype(int),
        "client_id": f["client_id"],
        "produit_id": f["produit_id"],
        "geographie_id": f["geographie_id"],
        "canal_vente": f["canal_vente"],
        "genre_cible": f["genre_cible"],
        "taille": f["taille"].astype(str),
        "quantite_vendue": f["quantite_vendue"],
        "prix_unitaire": (prix * 0.85).round(2),
        "remise": f["remise"].clip(upper=0.5),
    })


def ventes_synthetiques(debut_cmd, n, geo, clients, rng):
    jours, wj = poids_dates()
    dates = jours[rng.choice(len(jours), n, p=wj)]
    gidx = rng.choice(len(geo), n, p=poids_villes())
    geo_id = geo["geographie_id"].to_numpy()[gidx]
    indice_prix, part_web = infos_pays(geo)
    canal = np.where(rng.random(n) < part_web[gidx], "Online", "Retail")
    client = choisir_clients(geo_id, clients, rng)
    cmd = np.arange(debut_cmd, debut_cmd + n)

    nb = rng.choice([1, 2, 3], n, p=[0.65, 0.25, 0.10])
    i = np.repeat(np.arange(n), nb)
    m = len(i)
    pop = np.array([p[4] for p in PRODUITS])
    pidx = rng.choice(len(PRODUITS), m, p=pop / pop.sum())
    mois = pd.DatetimeIndex(dates).month.to_numpy()[i]
    proba_remise = np.select([mois == 11, np.isin(mois, [1, 7])], [0.45, 0.40], 0.18)
    genre = rng.choice(["Men", "Women", "Kids"], m, p=[0.47, 0.35, 0.18])
    taille = np.empty(m, dtype=object)
    for g, t in TAILLES.items():
        k = genre == g
        taille[k] = rng.choice(t, k.sum())
    return pd.DataFrame({
        "commande_id": cmd[i],
        "order_id_source": pd.array([pd.NA] * m, dtype="Int64"),
        "date_id": pd.DatetimeIndex(dates).strftime("%Y%m%d").astype(int).to_numpy()[i],
        "client_id": client[i],
        "produit_id": np.array([p[0] for p in PRODUITS])[pidx],
        "geographie_id": geo_id[i],
        "canal_vente": canal[i],
        "genre_cible": genre,
        "taille": taille,
        "quantite_vendue": rng.choice([1, 2, 3], m, p=[0.85, 0.12, 0.03]),
        "prix_unitaire": (np.array([p[3] for p in PRODUITS])[pidx] * indice_prix[gidx][i]).round(2),
        "remise": np.where(rng.random(m) < proba_remise, rng.choice([0.10, 0.15, 0.20, 0.25, 0.30, 0.40], m), 0.0),
    })


def montants(f):
    # Coût de revient : environ 55 % du prix catalogue (marge brute de Nike autour de 43-45 %)
    cout = f["produit_id"].map({p[0]: p[3] * 0.55 for p in PRODUITS})
    f["chiffre_affaires"] = (f["quantite_vendue"] * f["prix_unitaire"] * (1 - f["remise"])).round(2)
    f["benefices"] = (f["chiffre_affaires"] - f["quantite_vendue"] * cout).round(2)
    return f


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--source", default="source_kaggle", help="dossier des données Kaggle nettoyées")
    ap.add_argument("--out", default="data")
    ap.add_argument("--commandes", type=int, default=100_000, help="nombre de commandes ajoutées")
    ap.add_argument("--clients", type=int, default=None, help="défaut : commandes / 4")
    ap.add_argument("--lot", type=int, default=500_000)
    ap.add_argument("--seed", type=int, default=42)
    a = ap.parse_args()

    rng = np.random.default_rng(a.seed)
    os.makedirs(a.out, exist_ok=True)
    geo, produits, dates = dim_geographie(), dim_produit(), dim_date()
    clients = dim_client(a.clients or max(5_000, a.commandes // 4), geo, rng)
    for nom, df in [("dim_geographie", geo), ("dim_produit", produits), ("dim_date", dates),
                    ("categories", table_categories())]:
        df.to_csv(os.path.join(a.out, f"{nom}.csv"), index=False)

    chemin = os.path.join(a.out, "fait_ventes.csv")
    premiere = np.full(len(clients) + 1, 99999999, dtype=np.int64)  # 1re commande de chaque client (AAAAMMJJ)

    def ecrire(f, debut_id, entete):
        f = montants(f)
        f.insert(0, "vente_id", np.arange(debut_id, debut_id + len(f)))
        np.minimum.at(premiere, f["client_id"].to_numpy(), f["date_id"].to_numpy())
        f.to_csv(chemin, mode="w" if entete else "a", header=entete, index=False)
        return len(f)

    nb_ventes = ecrire(ventes_kaggle(a.source, geo, clients, rng), 1, True)
    prochaine_cmd = 2501
    fait = 0
    while fait < a.commandes:
        k = min(a.lot, a.commandes - fait)
        nb_ventes += ecrire(ventes_synthetiques(prochaine_cmd, k, geo, clients, rng), nb_ventes + 1, False)
        prochaine_cmd += k
        fait += k

    # Un client s'inscrit au plus tard le jour de sa 1re commande
    p = premiere[clients["client_id"].to_numpy()]
    first = pd.to_datetime(np.where(p < 99999999, p, 0).astype(str), format="%Y%m%d", errors="coerce")
    clients["date_inscription"] = np.where(first.notna() & (first < clients["date_inscription"]),
                                           first, clients["date_inscription"])
    clients["date_inscription"] = pd.to_datetime(clients["date_inscription"]).dt.date
    clients.drop(columns=["_geo", "_w"]).to_csv(os.path.join(a.out, "dim_client.csv"), index=False)

    for nom, n in [("fait_ventes", nb_ventes), ("dim_date", len(dates)), ("dim_client", len(clients)),
                   ("dim_produit", len(produits)), ("dim_geographie", len(geo)),
                   ("categories", len(table_categories()))]:
        print(f"{nom:<16} {n:>12,}")


if __name__ == "__main__":
    main()
