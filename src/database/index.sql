-- INDEX de nomes na tabela de ingredientes e donuts
CREATE INDEX `idx_ingredient_name` ON `donuts_ingredient` (`name`);
CREATE INDEX `idx_donut_name` ON `donuts_donut` (`name`);
CREATE INDEX `idx_donut_price` ON `donuts_donut`(price);
CREATE INDEX `idx_payment_date` ON `donuts_payment`(payment_date);
CREATE INDEX `idx_payment_method` ON `donuts_payment`(payment_method);

-- INDEX para relacionamentos em donuts_recipe
-- CREATE INDEX `idx_donuts_recipe_donut_id` ON `donuts_recipe` (`donut_id`);
-- CREATE INDEX `idx_donuts_recipe_ingredient_id` ON `donuts_recipe` (`ingredient_id`);
