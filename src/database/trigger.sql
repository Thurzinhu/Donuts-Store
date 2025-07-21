-- TRIGGER para impedir que um donut tenha um preço menor que seu custo de produção
DELIMITER $$

DROP TRIGGER IF EXISTS `valid_donut_price_before_insert`$$
CREATE TRIGGER `valid_donut_price_before_insert`
BEFORE INSERT ON `donuts_donut`
FOR EACH ROW
BEGIN
    DECLARE production_cost DECIMAL(10,2);

    SELECT `production_cost` INTO production_cost
    FROM `donut_cost`
    WHERE `donut_id` = NEW.`id`;

    IF NEW.`price` < production_cost THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Selling price cannot be less than ingredient cost.';
    END IF;
END$$

DROP TRIGGER IF EXISTS `valid_donut_price_before_update`$$
CREATE TRIGGER `valid_donut_price_before_update`
BEFORE UPDATE ON `donuts_donut`
FOR EACH ROW
BEGIN
    DECLARE production_cost DECIMAL(10,2);

    SELECT `production_cost` INTO production_cost
    FROM `donut_cost`
    WHERE `donut_id` = NEW.`id`;

    IF NEW.`price` < production_cost THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Selling price cannot be less than ingredient cost.';
    END IF;
END$$

DELIMITER ;

-- TRIGGER para impedir que ingredientes tenham um preço menor ou igual a zero
DELIMITER $$

DROP TRIGGER IF EXISTS `valid_ingredient_price_before_insert`$$
CREATE TRIGGER `valid_ingredient_price_before_insert`
BEFORE INSERT ON `donuts_ingredient`
FOR EACH ROW
BEGIN
    IF NEW.`price_per_unit` <= 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Ingredient price must be greater than zero';
    END IF;
END$$

DROP TRIGGER IF EXISTS `valid_ingredient_price_before_update`$$
CREATE TRIGGER `valid_ingredient_price_before_update`
BEFORE UPDATE ON `donuts_ingredient`
FOR EACH ROW
BEGIN
    IF NEW.`price_per_unit` <= 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Ingredient price must be greater than zero';
    END IF;
END$$

DELIMITER ;