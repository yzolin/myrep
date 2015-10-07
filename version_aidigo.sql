use shop;

CREATE INDEX idx_productlang ON productlang(PRODUCT_ID, LANG);

CREATE INDEX idx_catalog_pagelang ON catalog_pagelang(catalog_page_id,lang);