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

DROP VIEW IF EXISTS `customer_reviews`;
-- VIEW para recuperar todas as reviews de um customer
CREATE VIEW `customer_reviews` AS
SELECT
    `c`.`id` AS `customer_id`,
    `c`.`first_name`,
    `c`.`last_name`,
    `c`.`email`,
    `d`.`id` AS `donut_id`,
    `d`.`name` AS `donut_name`,
    `d`.`price` AS `donut_price`,
    `r`.`id` AS `review_id`,
    `r`.`comment`,
    `r`.`rating`,
    `r`.`review_date`
FROM `donuts_customer` AS `c`
INNER JOIN `donuts_review` AS `r` ON `r`.`customer_id` = `c`.`id`
INNER JOIN `donuts_donut` AS `d` ON `r`.`donut_id` = `d`.`id`
ORDER BY `c`.`last_name`, `c`.`first_name`, `r`.`review_date` DESC;


DROP VIEW IF EXISTS `customer_favorite_donuts`;
-- VIEW para recuperar os donuts favoritos de cada customer (rating 4 ou 5)
CREATE VIEW `customer_favorite_donuts` AS
SELECT
    `c`.`id` AS `customer_id`,
    `c`.`first_name`,
    `c`.`last_name`,
    `c`.`email`,
    `d`.`id` AS `donut_id`,
    `d`.`name` AS `donut_name`,
    `d`.`price` AS `donut_price`,
    `d`.`gluten_free`,
    `r`.`rating`,
    `r`.`comment`,
    `r`.`review_date`
FROM `donuts_customer` AS `c`
INNER JOIN `donuts_review` AS `r` ON `r`.`customer_id` = `c`.`id`
INNER JOIN `donuts_donut` AS `d` ON `r`.`donut_id` = `d`.`id`
WHERE `r`.`rating` >= 4
ORDER BY `c`.`last_name`, `c`.`first_name`, `r`.`rating` DESC, `r`.`review_date` DESC;


DROP VIEW IF EXISTS `recent_activity`;
-- VIEW para recuperar atividade recente (reviews dos últimos 30 dias)
CREATE VIEW `recent_activity` AS
SELECT
    `c`.`id` AS `customer_id`,
    `c`.`first_name`,
    `c`.`last_name`,
    `c`.`email`,
    `d`.`id` AS `donut_id`,
    `d`.`name` AS `donut_name`,
    `d`.`price` AS `donut_price`,
    `d`.`gluten_free`,
    `r`.`id` AS `review_id`,
    `r`.`rating`,
    `r`.`comment`,
    `r`.`review_date`,
    DATEDIFF(CURDATE(), `r`.`review_date`) AS `days_ago`
FROM `donuts_customer` AS `c`
INNER JOIN `donuts_review` AS `r` ON `r`.`customer_id` = `c`.`id`
INNER JOIN `donuts_donut` AS `d` ON `r`.`donut_id` = `d`.`id`
WHERE `r`.`review_date` >= DATE_SUB(CURDATE(), INTERVAL 30 DAY)
ORDER BY `r`.`review_date` DESC;


DROP VIEW IF EXISTS `review_statistics`;
-- VIEW para estatísticas gerais de todas as reviews
CREATE VIEW `review_statistics` AS
SELECT
    COUNT(*) AS `total_reviews`,
    ROUND(AVG(`rating`), 2) AS `average_rating`,
    COUNT(CASE WHEN `rating` = 5 THEN 1 END) AS `five_star_reviews`,
    COUNT(CASE WHEN `rating` = 4 THEN 1 END) AS `four_star_reviews`,
    COUNT(CASE WHEN `rating` = 3 THEN 1 END) AS `three_star_reviews`,
    COUNT(CASE WHEN `rating` = 2 THEN 1 END) AS `two_star_reviews`,
    COUNT(CASE WHEN `rating` = 1 THEN 1 END) AS `one_star_reviews`,
    COUNT(CASE WHEN `comment` IS NOT NULL AND `comment` != '' THEN 1 END) AS `reviews_with_comments`,
    ROUND((COUNT(CASE WHEN `rating` >= 4 THEN 1 END) / COUNT(*)) * 100, 2) AS `satisfaction_percentage`,
    MIN(`review_date`) AS `first_review_date`,
    MAX(`review_date`) AS `latest_review_date`
FROM `donuts_review`;


DROP VIEW IF EXISTS `review_trends`;
-- VIEW para análise de trends de reviews por período
CREATE VIEW `review_trends` AS
SELECT
    YEAR(`review_date`) AS `year`,
    MONTH(`review_date`) AS `month`,
    MONTHNAME(`review_date`) AS `month_name`,
    COUNT(*) AS `total_reviews`,
    ROUND(AVG(`rating`), 2) AS `avg_rating`,
    COUNT(CASE WHEN `rating` >= 4 THEN 1 END) AS `positive_reviews`,
    COUNT(CASE WHEN `rating` <= 2 THEN 1 END) AS `negative_reviews`,
    ROUND((COUNT(CASE WHEN `rating` >= 4 THEN 1 END) / COUNT(*)) * 100, 2) AS `positive_percentage`,
    COUNT(DISTINCT `customer_id`) AS `unique_customers`,
    COUNT(DISTINCT `donut_id`) AS `reviewed_donuts`
FROM `donuts_review`
GROUP BY YEAR(`review_date`), MONTH(`review_date`), MONTHNAME(`review_date`)
ORDER BY `year` DESC, `month` DESC;


DROP VIEW IF EXISTS `donut_rating_average`;
-- VIEW para média de avaliação por donut
CREATE VIEW `donut_rating_average` AS
SELECT
    `d`.`id` AS `donut_id`,
    `d`.`name` AS `donut_name`,
    `d`.`price` AS `donut_price`,
    `d`.`gluten_free`,
    `d`.`description`,
    COUNT(`r`.`rating`) AS `total_reviews`,
    ROUND(AVG(`r`.`rating`), 2) AS `average_rating`,
    MIN(`r`.`rating`) AS `lowest_rating`,
    MAX(`r`.`rating`) AS `highest_rating`,
    COUNT(CASE WHEN `r`.`rating` >= 4 THEN 1 END) AS `positive_reviews`,
    COUNT(CASE WHEN `r`.`rating` <= 2 THEN 1 END) AS `negative_reviews`,
    ROUND((COUNT(CASE WHEN `r`.`rating` >= 4 THEN 1 END) / COUNT(`r`.`rating`)) * 100, 2) AS `satisfaction_percentage`
FROM `donuts_donut` AS `d`
LEFT JOIN `donuts_review` AS `r` ON `r`.`donut_id` = `d`.`id`
GROUP BY `d`.`id`, `d`.`name`, `d`.`price`, `d`.`gluten_free`, `d`.`description`
ORDER BY `average_rating` DESC, `total_reviews` DESC;


DROP VIEW IF EXISTS `employee_overview`;
-- VIEW para visão geral dos funcionários com métricas calculadas
CREATE VIEW `employee_overview` AS
SELECT
    `id`,
    `name`,
    `role`,
    `hire_date`,
    `salary`,
    DATEDIFF(CURDATE(), `hire_date`) AS `days_employed`,
    ROUND(DATEDIFF(CURDATE(), `hire_date`) / 365.25, 1) AS `years_employed`,
    CASE 
        WHEN DATEDIFF(CURDATE(), `hire_date`) > 1095 THEN 'Veterano (3+ anos)'
        WHEN DATEDIFF(CURDATE(), `hire_date`) > 365 THEN 'Experiente (1-3 anos)'
        WHEN DATEDIFF(CURDATE(), `hire_date`) > 90 THEN 'Estabelecido (3-12 meses)'
        ELSE 'Novo (< 3 meses)'
    END AS `experience_level`,
    ROUND(`salary` * 12, 2) AS `annual_salary`,
    ROUND(`salary` * 13.33, 2) AS `annual_cost_with_benefits`
FROM `donuts_employee`
ORDER BY `hire_date` ASC;


DROP VIEW IF EXISTS `salary_analysis`;
-- VIEW para análise detalhada de salários por cargo e senioridade
CREATE VIEW `salary_analysis` AS
SELECT
    `role`,
    COUNT(*) AS `employee_count`,
    ROUND(MIN(`salary`), 2) AS `min_salary`,
    ROUND(MAX(`salary`), 2) AS `max_salary`,
    ROUND(AVG(`salary`), 2) AS `avg_salary`,
    ROUND(STDDEV(`salary`), 2) AS `salary_variance`,
    ROUND(AVG(DATEDIFF(CURDATE(), `hire_date`) / 365.25), 1) AS `avg_years_experience`,
    ROUND(SUM(`salary`), 2) AS `total_payroll_by_role`,
    ROUND((SUM(`salary`) / (SELECT SUM(`salary`) FROM `donuts_employee`)) * 100, 2) AS `payroll_percentage`
FROM `donuts_employee`
GROUP BY `role`
ORDER BY `avg_salary` DESC;


DROP VIEW IF EXISTS `payroll_summary`;
-- VIEW para resumo executivo da folha de pagamento
CREATE VIEW `payroll_summary` AS
SELECT
    COUNT(*) AS `total_employees`,
    ROUND(SUM(`salary`), 2) AS `monthly_payroll`,
    ROUND(SUM(`salary`) * 12, 2) AS `annual_payroll`,
    ROUND(AVG(`salary`), 2) AS `avg_salary`,
    ROUND(MIN(`salary`), 2) AS `lowest_salary`,
    ROUND(MAX(`salary`), 2) AS `highest_salary`,
    COUNT(DISTINCT `role`) AS `total_roles`,
    ROUND(AVG(DATEDIFF(CURDATE(), `hire_date`)), 0) AS `avg_tenure_days`,
    ROUND(AVG(DATEDIFF(CURDATE(), `hire_date`) / 365.25), 1) AS `avg_tenure_years`
FROM `donuts_employee`;


DROP VIEW IF EXISTS `employee_performance_potential`;
-- VIEW para análise de potencial baseada em tempo de casa e salário
CREATE VIEW `employee_performance_potential` AS
SELECT
    `e`.`id`,
    `e`.`name`,
    `e`.`role`,
    `e`.`hire_date`,
    `e`.`salary`,
    ROUND(DATEDIFF(CURDATE(), `e`.`hire_date`) / 365.25, 1) AS `years_employed`,
    ROUND(`e`.`salary` / (DATEDIFF(CURDATE(), `e`.`hire_date`) / 365.25 + 1), 2) AS `salary_per_year_ratio`,
    (SELECT ROUND(AVG(`salary`), 2) FROM `donuts_employee` WHERE `role` = `e`.`role`) AS `role_avg_salary`,
    CASE 
        WHEN `e`.`salary` > (SELECT AVG(`salary`) * 1.2 FROM `donuts_employee` WHERE `role` = `e`.`role`) THEN 'High Performer'
        WHEN `e`.`salary` < (SELECT AVG(`salary`) * 0.8 FROM `donuts_employee` WHERE `role` = `e`.`role`) THEN 'Entry Level'
        ELSE 'Standard'
    END AS `performance_tier`,
    CASE 
        WHEN DATEDIFF(CURDATE(), `e`.`hire_date`) > 1095 AND `e`.`salary` < (SELECT AVG(`salary`) * 1.1 FROM `donuts_employee` WHERE `role` = `e`.`role`) THEN 'Candidato a aumento'
        WHEN DATEDIFF(CURDATE(), `e`.`hire_date`) > 730 THEN 'Elegível para promoção'
        WHEN DATEDIFF(CURDATE(), `e`.`hire_date`) > 365 THEN 'Desenvolvimento de carreira'
        ELSE 'Período inicial'
    END AS `growth_opportunity`
FROM `donuts_employee` AS `e`
ORDER BY `salary_per_year_ratio` DESC;