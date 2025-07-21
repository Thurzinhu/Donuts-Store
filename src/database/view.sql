DROP VIEW IF EXISTS `donut_ingredients`;
-- VIEW para recuperar os ingredientes necessários para se fazer um determinado Donut
CREATE VIEW `donut_ingredients` AS
SELECT
    `d`.`id` AS `donut_id`,
    `d`.`name` AS `donut`,
    `i`.`name` AS `ingredient`,
    `r`.`quantity` AS `quantity`,
    `i`.`unit` AS `unit`
FROM `donuts_ingredient` AS `i`
INNER JOIN `donuts_recipe` AS `r` ON `r`.`ingredient_id` = `i`.`id`
INNER JOIN `donuts_donut` AS `d` ON `r`.`donut_id` = `d`.`id`
ORDER BY `d`.`name`;


DROP VIEW IF EXISTS `donut_recipe`;
-- VIEW para recuperar a receita para se fazer um Donut
CREATE VIEW `donut_recipe` AS
SELECT
    `d`.`id`,
    `d`.`name`,
    `d`.`description`,
    GROUP_CONCAT(CONCAT(`i`.`name`, ' (', `r`.`quantity`, ' ', `i`.`unit`, ')') SEPARATOR ', ') AS `Recipe`
FROM `donuts_donut` AS `d`
INNER JOIN `donuts_recipe` AS `r` ON `r`.`donut_id` = `d`.`id`
INNER JOIN `donuts_ingredient` AS `i` ON `r`.`ingredient_id` = `i`.`id`
GROUP BY `d`.`id`, `d`.`name`, `d`.`description`
ORDER BY `d`.`name`;


DROP VIEW IF EXISTS `donut_cost`;
-- VIEW para recuperar o custo de produção de cada donut
CREATE VIEW `donut_cost` AS
SELECT
    `d`.`id` AS `donut_id`,
    `d`.`name` AS `donut`,
    SUM(`r`.`quantity` * `i`.`price_per_unit`) AS `production_cost`
FROM `donuts_donut` AS `d`
INNER JOIN `donuts_recipe` AS `r` ON `r`.`donut_id` = `d`.`id`
INNER JOIN `donuts_ingredient` AS `i` ON `r`.`ingredient_id` = `i`.`id`
GROUP BY `d`.`id`, `d`.`name`
ORDER BY `d`.`name`;


DROP VIEW IF EXISTS `donut_profit`;
-- VIEW para recuperar o lucro esperado pela venda de cada donut
CREATE VIEW `donut_profit` AS
SELECT
    `d`.`id` AS `donut_id`,
    `d`.`name` AS `donut`,
    `d`.`price` AS `selling_price`,
    SUM(`r`.`quantity` * `i`.`price_per_unit`) AS `production_cost`,
    (`d`.`price` - SUM(`r`.`quantity` * `i`.`price_per_unit`)) AS `profit`
FROM `donuts_donut` AS `d`
INNER JOIN `donuts_recipe` AS `r` ON `r`.`donut_id` = `d`.`id`
INNER JOIN `donuts_ingredient` AS `i` ON `r`.`ingredient_id` = `i`.`id`
GROUP BY `d`.`id`, `d`.`name`, `d`.`price`
ORDER BY `d`.`name`;


DROP VIEW IF EXISTS `gluten_free_donuts`;
-- VIEW para recuperar os donuts sem glúten
CREATE VIEW `gluten_free_donuts` AS
SELECT
    `id`,
    `name`,
    `price`,
    `description`
FROM `donuts_donut`
WHERE `gluten_free` = 1;