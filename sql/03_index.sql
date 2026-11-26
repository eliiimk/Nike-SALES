-- Index sur les colonnes filtrées dans les requêtes du benchmark
CREATE INDEX idx_ventes_client ON fait_ventes (client_id);
CREATE INDEX idx_ventes_date ON fait_ventes (date_id);
CREATE INDEX idx_ventes_produit ON fait_ventes (produit_id);

ANALYZE fait_ventes;
