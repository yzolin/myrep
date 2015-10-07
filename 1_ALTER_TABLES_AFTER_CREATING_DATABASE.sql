/**
 * Создание дополнительных объектов в базе.
 * Скрипт выполняется только один раз после развертывания базы
 * 
 * @author yzolin
 */
use shop;

CREATE INDEX idx_productlang ON productlang(PRODUCT_ID, LANG);

CREATE INDEX idx_catalog_pagelang ON catalog_pagelang(CATALOG_PAGE_ID,LANG);