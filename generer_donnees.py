"""
Génère les données du projet fil rouge (ventes Nike, données fictives).

- Les 2 500 commandes du dataset Kaggle (Inde, nettoyées) sont conservées.
- Des commandes sont ajoutées sur les autres marchés de Nike, avec une répartition
  proche des chiffres réels de l'exercice 2025 (North America 44 %, EMEA 27 %,
  Greater China 15 %, APLA 14 %).
- Tous les montants sont en dollars (USD).

Usage :
    python generer_donnees.py                       # 100 000 commandes (~145 000 lignes)
    python generer_donnees.py --commandes 6900000   # ~10 millions de lignes (TD performance)
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


def referentiels():
    zones = pd.DataFrame([(z, n) for z, n, _ in ZONES], columns=["zone_id", "nom_zone"])
    pays, regions = [], []
    rid = 1
    for pid, (nom, zone, *_ , villes) in enumerate(PAYS, start=1):
        pays.append((pid, nom, zone))
        for v, _ in villes:
            regions.append((rid, v, pid))
            rid += 1
    pays = pd.DataFrame(pays, columns=["pays_id", "nom_pays", "zone_id"])
    regions = pd.DataFrame(regions, columns=["region_id", "region_nom", "pays_id"])
    univers = pd.DataFrame(UNIVERS, columns=["univers_id", "nom_univers"])
    categories = pd.DataFrame(CATEGORIES, columns=["categorie_id", "nom_categorie", "univers_id"])
    produits = pd.DataFrame([p[:4] for p in PRODUITS], columns=["produit_id", "nom_produit", "categorie_id", "prix_catalogue"])
    return zones, pays, regions, univers, categories, produits


def poids_villes(regions):
    """Probabilité de chaque ville = part de la zone x part du pays x poids de la ville."""
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


def source_kaggle(dossier_source, regions, produits, rng):
    """Commandes Kaggle déjà nettoyées (Inde) : montants convertis en USD, tailles en pointures."""
    c = pd.read_csv(os.path.join(dossier_source, "commandes.csv"))
    l = pd.read_csv(os.path.join(dossier_source, "lignes_commande.csv"))
    anciennes = pd.read_csv(os.path.join(dossier_source, "regions.csv"))
    nom_ville = c["region_id"].map(dict(zip(anciennes["region_id"], anciennes["region_nom"])))
    c["region_id"] = nom_ville.map(dict(zip(regions["region_nom"], regions["region_id"])))
    # Les prix d'origine sont tirés au hasard (sans lien avec le produit) : on applique le prix
    # catalogue en USD avec l'indice de prix de l'Inde, et on plafonne les remises à 50 %
    prix = l["produit_id"].map(dict(zip(produits["produit_id"], produits["prix_catalogue"])))
    l["prix_unitaire"] = (prix * 0.85).round(2)
    l["remise"] = l["remise"].clip(upper=0.5)
    # Le fichier d'origine mélange tailles de vêtements (M/L/XL) et pointures : on garde des pointures
    pas_pointure = ~l["taille"].astype(str).str.isdigit()
    l.loc[pas_pointure, "taille"] = [rng.choice(TAILLES[g]) for g in l.loc[pas_pointure, "genre_cible"]]
    return c, l


def generer(debut_cmd, debut_ligne, n, regions, produits, rng):
    jours, wj = poids_dates()
    dates = jours[rng.choice(len(jours), n, p=wj)]
    villes = rng.choice(regions["region_id"].to_numpy(), n, p=poids_villes(regions))

    pays_de_ville = regions.set_index("region_id")["pays_id"]
    infos = {i + 1: (p[3], p[4]) for i, p in enumerate(PAYS)}
    pays = pays_de_ville.loc[villes].to_numpy()
    part_web = np.array([infos[p][1] for p in pays])
    indice_prix = np.array([infos[p][0] for p in pays])
    canal = np.where(rng.random(n) < part_web, "Online", "Retail")

    cmd = pd.DataFrame({
        "commande_id": np.arange(debut_cmd, debut_cmd + n),
        "order_id_source": pd.array([pd.NA] * n, dtype="Int64"),
        "date_commande": dates.date,
        "canal_vente": canal,
        "region_id": villes,
    })

    nb = rng.choice([1, 2, 3], n, p=[0.65, 0.25, 0.10])
    m = int(nb.sum())
    idx_cmd = np.repeat(np.arange(n), nb)
    pop = np.array([p[4] for p in PRODUITS])
    pidx = rng.choice(len(PRODUITS), m, p=pop / pop.sum())
    prix = np.array([p[3] for p in PRODUITS])[pidx] * indice_prix[idx_cmd]
    # Soldes plus fréquentes en janvier et en été, Black Friday en novembre
    mois = pd.DatetimeIndex(dates).month.to_numpy()[idx_cmd]
    proba_remise = np.select([mois == 11, np.isin(mois, [1, 7])], [0.45, 0.40], 0.18)
    remise = np.where(rng.random(m) < proba_remise, rng.choice([0.10, 0.15, 0.20, 0.25, 0.30, 0.40], m), 0.0)
    genre = rng.choice(["Men", "Women", "Kids"], m, p=[0.47, 0.35, 0.18])
    taille = np.empty(m, dtype=object)
    for g, tailles in TAILLES.items():
        k = genre == g
        taille[k] = rng.choice(tailles, k.sum())

    lignes = pd.DataFrame({
        "ligne_id": np.arange(debut_ligne, debut_ligne + m),
        "commande_id": cmd["commande_id"].to_numpy()[idx_cmd],
        "produit_id": np.array([p[0] for p in PRODUITS])[pidx],
        "genre_cible": genre,
        "taille": taille,
        "quantite_vendue": rng.choice([1, 2, 3], m, p=[0.85, 0.12, 0.03]),
        "prix_unitaire": prix.round(2),
        "remise": remise,
    })
    return cmd, lignes


def calculer_montants(lignes, produits, rng):
    # Coût de revient : environ 55 % du prix catalogue (marge brute de Nike autour de 43-45 %)
    cout = lignes["produit_id"].map(dict(zip(produits["produit_id"], produits["prix_catalogue"] * 0.55)))
    lignes["chiffre_affaires"] = (lignes["quantite_vendue"] * lignes["prix_unitaire"] * (1 - lignes["remise"])).round(2)
    lignes["benefices"] = (lignes["chiffre_affaires"] - lignes["quantite_vendue"] * cout).round(2)
    return lignes


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--source", default="source_kaggle", help="dossier des données Kaggle nettoyées")
    ap.add_argument("--out", default="data")
    ap.add_argument("--commandes", type=int, default=100_000, help="nombre de commandes ajoutées")
    ap.add_argument("--lot", type=int, default=500_000)
    ap.add_argument("--seed", type=int, default=42)
    a = ap.parse_args()

    rng = np.random.default_rng(a.seed)
    os.makedirs(a.out, exist_ok=True)
    zones, pays, regions, univers, categories, produits = referentiels()
    for nom, df in [("zones", zones), ("pays", pays), ("regions", regions), ("univers", univers),
                    ("categories_produits", categories), ("produits", produits)]:
        df.to_csv(os.path.join(a.out, f"{nom}.csv"), index=False)

    c, l = source_kaggle(a.source, regions, produits, rng)
    pc, pl = os.path.join(a.out, "commandes.csv"), os.path.join(a.out, "lignes_commande.csv")
    c.to_csv(pc, index=False)
    calculer_montants(l, produits, rng).to_csv(pl, index=False)
    n_cmd, n_lig = len(c), len(l)

    fait = 0
    while fait < a.commandes:
        k = min(a.lot, a.commandes - fait)
        sc, sl = generer(n_cmd + 1, n_lig + 1, k, regions, produits, rng)
        sc.to_csv(pc, mode="a", header=False, index=False)
        calculer_montants(sl, produits, rng).to_csv(pl, mode="a", header=False, index=False)
        n_cmd += len(sc)
        n_lig += len(sl)
        fait += k

    for nom, n in [("zones", len(zones)), ("pays", len(pays)), ("regions", len(regions)), ("univers", len(univers)),
                   ("categories_produits", len(categories)), ("produits", len(produits)),
                   ("commandes", n_cmd), ("lignes_commande", n_lig)]:
        print(f"{nom:<20} {n:>12,}")


if __name__ == "__main__":
    main()
