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

CREATE TABLE IF NOT EXISTS `donuts_customer` (
    `id` INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
    `first_name` VARCHAR(100) NOT NULL,
    `last_name` VARCHAR(100) NOT NULL,
    `email` VARCHAR(255) NOT NULL UNIQUE
);

CREATE TABLE IF NOT EXISTS `donuts_employee` (
    `id` INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
    `name` VARCHAR(100) NOT NULL,
    `role` VARCHAR(100) NOT NULL,
    `hire_date` DATE NOT NULL,
    `salary` DECIMAL(10, 2) NOT NULL CHECK (`salary` >= 0)
);

CREATE TABLE IF NOT EXISTS `donuts_review` (
    `id` INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
    `comment` VARCHAR(500) NULL,
    `rating` INT NOT NULL CHECK (`rating` >= 1 AND `rating` <= 5),
    `review_date` DATETIME NOT NULL,
    `customer_id` INT NOT NULL,
    `donut_id` INT NOT NULL,
    CONSTRAINT `fk_review_customer` FOREIGN KEY (`customer_id`) REFERENCES `donuts_customer`(`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_review_donut` FOREIGN KEY (`donut_id`) REFERENCES `donuts_donut`(`id`) ON DELETE CASCADE,
    CONSTRAINT `unique_customer_donut_review` UNIQUE (`customer_id`, `donut_id`)
);

CREATE TABLE IF NOT EXISTS `Order` (
    `id` INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
    `order_number` BIGINT NOT NULL UNIQUE,
    `customer_id` INT NOT NULL,
    `timestamp` DATE NOT NULL,
    `employee_id` BIGINT NOT NULL,
    CONSTRAINT `fk_order_customer` FOREIGN KEY (`customer_id`) REFERENCES `donuts_customer`(`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_order_employee` FOREIGN KEY (`employee_id`) REFERENCES `donuts_employee`(`id`) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS `donuts_donut_order` (
    `id` INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
    `donut_id` INT NOT NULL,
    `order_id` INT NOT NULL,
    `quantity` INT NOT NULL CHECK (`quantity` > 0),
    CONSTRAINT `fk_donutorder_donut` FOREIGN KEY (`donut_id`) REFERENCES `donuts_donut`(`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_donutorder_order` FOREIGN KEY (`order_id`) REFERENCES `donuts_order`(`id`) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS `Payment` (
    `id` BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY,
    `order_id` BIGINT NOT NULL,
    `payment_method` VARCHAR(50) NOT NULL,
    `amount_paid` DECIMAL(10, 2) NOT NULL CHECK (`amount_paid` >= 0),
    `payment_date` DATE NOT NULL,
    CONSTRAINT `fk_payment_order` FOREIGN KEY (`order_id`) REFERENCES `donuts_order`(`id`) ON DELETE CASCADE
);
