CREATE TABLE IF NOT EXISTS `donuts_ingredient` (
    `id` INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
    `name` VARCHAR(100) NOT NULL,
    `price_per_unit` DECIMAL(6, 2) NOT NULL CHECK (`price_per_unit` > 0),
    `unit` VARCHAR(10) NOT NULL
);

CREATE TABLE IF NOT EXISTS `donuts_donut` (
    `id` INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
    `name` VARCHAR(100) NOT NULL,
    `gluten_free` BOOLEAN NOT NULL,
    `price` DECIMAL(6, 2) NOT NULL CHECK (`price` >= 0),
    `description` TEXT NULL
);

CREATE TABLE IF NOT EXISTS `donuts_recipe` (
    `id` INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
    `quantity` DECIMAL(6, 2) NOT NULL CHECK (`quantity` > 0),
    `donut_id` INT NOT NULL,
    `ingredient_id` INT NOT NULL,
    CONSTRAINT `fk_donut` FOREIGN KEY (`donut_id`) REFERENCES `donuts_donut`(`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_ingredient` FOREIGN KEY (`ingredient_id`) REFERENCES `donuts_ingredient`(`id`) ON DELETE CASCADE,
    CONSTRAINT `unique_donut_ingredient` UNIQUE (`donut_id`, `ingredient_id`)
);
