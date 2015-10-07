use shop;

DELIMITER $$

DROP PROCEDURE IF EXISTS AIDIGO_EXPORT_SHOP $$
CREATE PROCEDURE AIDIGO_EXPORT_SHOP()
BEGIN
    DECLARE done INT DEFAULT 0;

    DECLARE vAPPLYING_ID INT;
    DECLARE vAPPLYING_NAME CHAR(255);

    DECLARE vCONTENT_ID INT;
    DECLARE vCONTENT_NAME CHAR(255);

    DECLARE vIMAGE_POSITION INT;

    DECLARE curapplyings CURSOR FOR
    SELECT A.id,
        A.name
    FROM applyings_products AP
        JOIN applyings A
            ON AP.applying_id = A.id
    GROUP BY A.id,
        A.name
    ORDER BY A.id,
        A.name;

    DECLARE curcontents CURSOR FOR
    SELECT C.id,
        C.name
    FROM contents_products CP
        JOIN contents C
            ON CP.contents_id = C.id
    GROUP BY C.id,
        C.name
    ORDER BY C.id,
        C.name;

    DECLARE curimages CURSOR FOR
    SELECT DISTINCT I.image_position
    FROM ttr_image I
    ORDER BY I.image_position;

    DECLARE CONTINUE HANDLER FOR SQLSTATE '02000' SET done = 1;

    SET storage_engine = MYISAM;

    -- -------------------------------------------------------------------------
    -- Основные данные
    -- -------------------------------------------------------------------------
    DROP TEMPORARY TABLE IF EXISTS ttr_product;
    CREATE TEMPORARY TABLE ttr_product
    SELECT
        P.id, -- ID
        P.alias,
        P.name,
        P.text, -- Описание
        P.published,
        P.in_stock,
        P.price,
        P.true_price,
        P.special_price,
        P.rating,
        P.votes,
        P.product_code,
        P.type_weight,
        P.weight, -- Характеристики | Вес брутто
        P.weight_without, -- Характеристики | Вес нетто
        P.barcode, -- Характеристики | Штрих-код
        P.analog,
        P.catalog_id,
        CR.l_name AS catalog_name_ru,
        CE.l_name AS catalog_name_en,
        P.brand_id,
        B.alias AS brand_alias,
        B.name AS brand_name,
        P.gvk,
        P.exp_date, -- Характеристики | Срок годности
        P.pack, -- Характеристики | В коробке
        P.price_status,
        P.contents_text,
        PLR.l_name AS l_name_ru,
        PLR.l_text AS l_text_ru,
        PLR.l_gvk AS l_gvk_ru,
        PLR.l_contents_text AS l_contents_text_ru,
        PLE.l_name AS l_name_en,
        PLE.l_text AS l_text_n,
        PLE.l_gvk AS l_gvk_en,
        PLE.l_contents_text AS l_contents_text_en

    FROM products P
        LEFT JOIN productlang PLR
            ON P.ID = PLR.PRODUCT_ID
            AND PLR.LANG = 'ru'
        LEFT JOIN productlang PLE
            ON P.ID = PLE.PRODUCT_ID
            AND PLE.LANG = 'en'
        LEFT JOIN brands B
            ON P.brand_id = B.id
        LEFT JOIN catalog_pagelang CR
            ON P.catalog_id = CR.catalog_page_id
            AND CR.lang = 'ru'
        LEFT JOIN catalog_pagelang CE
            ON P.catalog_id = CE.catalog_page_id
            AND CE.lang = 'en'
    GROUP BY P.id;
    CREATE INDEX idx_ttr_product ON ttr_product(id);

    DROP TEMPORARY TABLE IF EXISTS ttr_product_header;
    CREATE TEMPORARY TABLE ttr_product_header
    SELECT
        'id' AS id,
        'alias' AS alias,
        'name' AS name,
        'text' AS text,
        'published' AS published,
        'in_stock' AS in_stock,
        'price' AS price,
        'true_price' AS true_price,
        'special_price' AS special_price,
        'rating' AS rating,
        'votes' AS votes,
        'product_code' AS product_code,
        'type_weight' AS type_weight,
        'weight' AS weight,
        'weight_without' AS weight_without,
        'barcode' AS barcode,
        'analog' AS analog,
        'catalog_id' AS catalog_id,
        'catalog_name_ru' AS catalog_name_ru,
        'catalog_name_en' AS catalog_name_en,
        'brand_id' AS brand_id,
        'brand_alias' AS brand_alias,
        'brand_name' AS brand_name,
        'gvk' AS gvk,
        'exp_date' AS exp_date,
        'pack' AS pack,
        'price_status' AS price_status,
        'contents_text' AS contents_text,
        'l_name_ru' AS l_name_ru,
        'l_text_ru' AS l_text_ru,
        'l_gvk_ru' AS l_gvk_ru,
        'l_contents_text_ru' AS l_contents_text_ru,
        'l_name_en' AS l_name_en,
        'l_text_n' AS l_text_n,
        'l_gvk_en' AS l_gvk_en,
        'l_contents_text_en' AS l_contents_text_en;


    -- -------------------------------------------------------------------------
    -- Основные данные
    -- -------------------------------------------------------------------------

    -- -------------------------------------------------------------------------
    -- Применение
    -- -------------------------------------------------------------------------
    SET @SQLS_APPLYING = '';
    SET @SQLS_APPLYING_HEADER = '';
    SET done = 0;
    OPEN curapplyings;
    FETCH curapplyings INTO vAPPLYING_ID, vAPPLYING_NAME;
    WHILE done = 0 DO 

        SET @SQLS_APPLYING = CONCAT (@SQLS_APPLYING,
            ',MAX(IF(A.id = ', vAPPLYING_ID, ', A.name, NULL)) AS applying_', vAPPLYING_ID);

        SET @SQLS_APPLYING_HEADER = CONCAT (@SQLS_APPLYING_HEADER,
            ',''', vAPPLYING_NAME,''' AS applying_', vAPPLYING_ID);

        SET done = 0;
        FETCH curapplyings INTO vAPPLYING_ID, vAPPLYING_NAME;
    END WHILE;
    CLOSE curapplyings;

    DROP TEMPORARY TABLE IF EXISTS ttr_product_apllying;
    SET @SQLS = CONCAT('CREATE TEMPORARY TABLE ttr_product_apllying AS
    SELECT AP.product_id AS applying_product_id
        ',
        @SQLS_APPLYING,
        '
    FROM applyings_products AP
        JOIN applyings A
            ON AP.applying_id = A.id
    GROUP BY AP.product_id');

    PREPARE STMT FROM @SQLS;
    EXECUTE STMT;
    DEALLOCATE PREPARE STMT;

    CREATE INDEX idx_ttr_product_apllying ON ttr_product_apllying(APPLYING_PRODUCT_ID);

    -- шапка
    DROP TEMPORARY TABLE IF EXISTS ttr_product_apllying_header;
    SET @SQLS = CONCAT('CREATE TEMPORARY TABLE ttr_product_apllying_header AS
    SELECT ''applying_product_id'' AS applying_product_id
        ',
        @SQLS_APPLYING_HEADER);

    PREPARE STMT FROM @SQLS;
    EXECUTE STMT;
    DEALLOCATE PREPARE STMT;
    -- -------------------------------------------------------------------------
    -- Применение
    -- -------------------------------------------------------------------------


    -- -------------------------------------------------------------------------
    -- Картинки
    -- -------------------------------------------------------------------------
    SET @IMAGE_POSITION = 1;
    SET @PRODUCT_ID_OLD = 0;
    DROP TEMPORARY TABLE IF EXISTS ttr_image;
    CREATE TEMPORARY TABLE ttr_image
    SELECT
        Z.product_id,
        Z.name,
        CAST(IF(Z.product_id = @PRODUCT_ID_OLD, @IMAGE_POSITION:=@IMAGE_POSITION + 1, @IMAGE_POSITION:=1) AS DECIMAL(5,0)) AS image_position,
        @PRODUCT_ID_OLD:=Z.product_id
    FROM
    (SELECT I.model_id AS product_id,
        I.position,
        I.name
    FROM images I
    WHERE I.model = 'Product'
    ORDER BY
        I.model_id,
        I.position,
        I.name) Z;

    SET @SQLS_IMAGES = '';
    SET @SQLS_IMAGES_HEADER = '';
    SET done = 0;
    OPEN curimages;
    FETCH curimages INTO vIMAGE_POSITION;
    WHILE done = 0 DO 

        SET @SQLS_IMAGES = CONCAT (@SQLS_IMAGES,
            ',MAX(IF(I.image_position = ', vIMAGE_POSITION, ', I.name, NULL)) AS image_', vIMAGE_POSITION);

        SET @SQLS_IMAGES_HEADER = CONCAT (@SQLS_IMAGES_HEADER,
            ',''image_', vIMAGE_POSITION,''' AS image_', vIMAGE_POSITION);

        SET done = 0;
        FETCH curimages INTO vIMAGE_POSITION;
    END WHILE;
    CLOSE curimages;

    DROP TEMPORARY TABLE IF EXISTS ttr_product_image;
    SET @SQLS = CONCAT('CREATE TEMPORARY TABLE ttr_product_image AS
    SELECT I.product_id AS image_product_id
        ',
        @SQLS_IMAGES,
        '
    FROM ttr_image I
    GROUP BY I.product_id');

    PREPARE STMT FROM @SQLS;
    EXECUTE STMT;
    DEALLOCATE PREPARE STMT;

    CREATE INDEX idx_ttr_product_image ON ttr_product_image(IMAGE_PRODUCT_ID);

    -- шапка
    DROP TEMPORARY TABLE IF EXISTS ttr_product_image_header;
    SET @SQLS = CONCAT('CREATE TEMPORARY TABLE ttr_product_image_header AS
    SELECT ''image_product_id'' AS image_product_id
        ',
        @SQLS_IMAGES_HEADER);

    PREPARE STMT FROM @SQLS;
    EXECUTE STMT;
    DEALLOCATE PREPARE STMT;
    -- -------------------------------------------------------------------------
    -- Картинки
    -- -------------------------------------------------------------------------

    -- -------------------------------------------------------------------------
    -- Состав
    -- -------------------------------------------------------------------------
    SET @SQLS_CONTENT = '';
    SET @SQLS_CONTENT_HEADER = '';
    SET done = 0;
    OPEN curcontents;
    FETCH curcontents INTO vCONTENT_ID, vCONTENT_NAME;
    WHILE done = 0 DO 

        SET @SQLS_CONTENT = CONCAT (@SQLS_CONTENT,
            ',MAX(IF(C.id = ', vCONTENT_ID, ', C.name, NULL)) AS content_', vCONTENT_ID);

        SET @SQLS_CONTENT_HEADER = CONCAT (@SQLS_CONTENT_HEADER,
            ',''', vCONTENT_NAME,''' AS content_', vCONTENT_ID);

        SET done = 0;
        FETCH curcontents INTO vCONTENT_ID, vCONTENT_NAME;
    END WHILE;
    CLOSE curcontents;

    DROP TEMPORARY TABLE IF EXISTS ttr_product_content;
    SET @SQLS = CONCAT('CREATE TEMPORARY TABLE ttr_product_content AS
    SELECT CP.product_id AS content_product_id
        ',
        @SQLS_CONTENT,
        '
    FROM contents_products CP
        JOIN contents C
            ON CP.contents_id = C.id
    GROUP BY CP.product_id');

    PREPARE STMT FROM @SQLS;
    EXECUTE STMT;
    DEALLOCATE PREPARE STMT;

    CREATE INDEX idx_ttr_product_content ON ttr_product_content(CONTENT_PRODUCT_ID);

    -- шапка
    DROP TEMPORARY TABLE IF EXISTS ttr_product_content_header;
    SET @SQLS = CONCAT('CREATE TEMPORARY TABLE ttr_product_content_header AS
    SELECT ''content_product_id'' AS content_product_id
        ',
        @SQLS_CONTENT_HEADER);

    PREPARE STMT FROM @SQLS;
    EXECUTE STMT;
    DEALLOCATE PREPARE STMT;
    -- -------------------------------------------------------------------------
    -- Состав
    -- -------------------------------------------------------------------------

    -- -------------------------------------------------------------------------
    -- Общая таблица с данными
    -- -------------------------------------------------------------------------
--     DROP TEMPORARY TABLE IF EXISTS ttr_product_list_header;
--     CREATE TEMPORARY TABLE ttr_product_list_header AS
--     SELECT P.*,
--         A.*,
--         I.*,
--         C.*
--     FROM ttr_product_header P
--         LEFT JOIN ttr_product_apllying_header A
--             ON TRUE
--         LEFT JOIN ttr_product_image_header I 
--             ON TRUE
--         LEFT JOIN ttr_product_content_header C
--             ON TRUE;
-- 
-- 
--     DROP TEMPORARY TABLE IF EXISTS ttr_product_list;
--     CREATE TEMPORARY TABLE ttr_product_list AS
--     SELECT P.*,
--         A.*,
--         I.*,
--         C.*
--     FROM ttr_product P
--         LEFT JOIN ttr_product_apllying A
--             ON P.Id = A.APPLYING_PRODUCT_ID
--         LEFT JOIN ttr_product_image I 
--             ON P.Id = I.IMAGE_PRODUCT_ID
--         LEFT JOIN ttr_product_content C
--             ON P.Id = C.CONTENT_PRODUCT_ID;
-- 
--     SELECT *
--     FROM ttr_product_list_header
--     UNION ALL
--     SELECT *
--     FROM ttr_product_list
--     INTO OUTFILE '/home/yzolin/tocsv/aidigo_products.csv'
--     FIELDS TERMINATED BY ';' ENCLOSED BY '"' LINES TERMINATED BY '\n';

    SELECT P.*,
        A.*,
        I.*,
        C.*
    FROM ttr_product_header P
        LEFT JOIN ttr_product_apllying_header A
            ON TRUE
        LEFT JOIN ttr_product_image_header I 
            ON TRUE
        LEFT JOIN ttr_product_content_header C
            ON TRUE
    UNION ALL
    SELECT P.*,
        A.*,
        I.*,
        C.*
    FROM ttr_product P
        LEFT JOIN ttr_product_apllying A
            ON P.Id = A.APPLYING_PRODUCT_ID
        LEFT JOIN ttr_product_image I 
            ON P.Id = I.IMAGE_PRODUCT_ID
        LEFT JOIN ttr_product_content C
            ON P.Id = C.CONTENT_PRODUCT_ID
    INTO OUTFILE '/home/yzolin/tocsv/aidigo_products.csv'
    FIELDS TERMINATED BY ';' ENCLOSED BY '"' LINES TERMINATED BY '\n';
    -- -------------------------------------------------------------------------
    -- Общая таблица с данными
    -- -------------------------------------------------------------------------

END $$