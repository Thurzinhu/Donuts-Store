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

-- TRIGGER 1: Validação de rating nas reviews (deve estar entre 1 e 5)
DELIMITER $$

DROP TRIGGER IF EXISTS `valid_review_rating_before_insert`$$
CREATE TRIGGER `valid_review_rating_before_insert`
BEFORE INSERT ON `donuts_review`
FOR EACH ROW
BEGIN
    IF NEW.`rating` < 1 OR NEW.`rating` > 5 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Review rating must be between 1 and 5';
    END IF;
END$$

DROP TRIGGER IF EXISTS `valid_review_rating_before_update`$$
CREATE TRIGGER `valid_review_rating_before_update`
BEFORE UPDATE ON `donuts_review`
FOR EACH ROW
BEGIN
    IF NEW.`rating` < 1 OR NEW.`rating` > 5 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Review rating must be between 1 and 5';
    END IF;
END$$

DELIMITER ;

-- TRIGGER 4: Prevenção de reviews duplicadas (mesmo cliente, mesmo donut)
DELIMITER $$

DROP TRIGGER IF EXISTS `prevent_duplicate_reviews_before_insert`$$
CREATE TRIGGER `prevent_duplicate_reviews_before_insert`
BEFORE INSERT ON `donuts_review`
FOR EACH ROW
BEGIN
    DECLARE review_count INT;
    
    SELECT COUNT(*) INTO review_count
    FROM `donuts_review`
    WHERE `customer_id` = NEW.`customer_id` 
      AND `donut_id` = NEW.`donut_id`;
    
    IF review_count > 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Customer has already reviewed this donut';
    END IF;
END$$

DELIMITER ;

-- TRIGGER 9: Log de auditoria para mudanças nas reviews
-- Primeiro, vamos criar a tabela de auditoria se não existir
CREATE TABLE IF NOT EXISTS `review_audit_log` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `review_id` INT,
    `action_type` ENUM('INSERT', 'UPDATE', 'DELETE'),
    `old_rating` INT,
    `new_rating` INT,
    `old_comment` TEXT,
    `new_comment` TEXT,
    `changed_by` VARCHAR(255),
    `change_timestamp` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX `idx_review_id` (`review_id`),
    INDEX `idx_timestamp` (`change_timestamp`)
);

DELIMITER $$

DROP TRIGGER IF EXISTS `review_audit_after_insert`$$
CREATE TRIGGER `review_audit_after_insert`
AFTER INSERT ON `donuts_review`
FOR EACH ROW
BEGIN
    INSERT INTO `review_audit_log` (
        `review_id`, `action_type`, `new_rating`, `new_comment`, `changed_by`
    ) VALUES (
        NEW.`id`, 'INSERT', NEW.`rating`, NEW.`comment`, USER()
    );
END$$

DROP TRIGGER IF EXISTS `review_audit_after_update`$$
CREATE TRIGGER `review_audit_after_update`
AFTER UPDATE ON `donuts_review`
FOR EACH ROW
BEGIN
    INSERT INTO `review_audit_log` (
        `review_id`, `action_type`, `old_rating`, `new_rating`, 
        `old_comment`, `new_comment`, `changed_by`
    ) VALUES (
        NEW.`id`, 'UPDATE', OLD.`rating`, NEW.`rating`, 
        OLD.`comment`, NEW.`comment`, USER()
    );
END$$

DROP TRIGGER IF EXISTS `review_audit_after_delete`$$
CREATE TRIGGER `review_audit_after_delete`
AFTER DELETE ON `donuts_review`
FOR EACH ROW
BEGIN
    INSERT INTO `review_audit_log` (
        `review_id`, `action_type`, `old_rating`, `old_comment`, `changed_by`
    ) VALUES (
        OLD.`id`, 'DELETE', OLD.`rating`, OLD.`comment`, USER()
    );
END$$

DELIMITER ;

-- CUSTOMER AUDIT SYSTEM: Log de auditoria para customers
-- Tabela para armazenar histórico de mudanças nos customers
CREATE TABLE IF NOT EXISTS `customer_audit_log` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `customer_id` INT,
    `action_type` ENUM('INSERT', 'UPDATE', 'DELETE'),
    `old_first_name` VARCHAR(100),
    `new_first_name` VARCHAR(100),
    `old_last_name` VARCHAR(100),
    `new_last_name` VARCHAR(100),
    `old_email` VARCHAR(255),
    `new_email` VARCHAR(255),
    `changed_by` VARCHAR(255),
    `change_timestamp` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `ip_address` VARCHAR(45), -- Para IPv4 e IPv6
    `user_agent` TEXT,
    INDEX `idx_customer_id` (`customer_id`),
    INDEX `idx_timestamp` (`change_timestamp`),
    INDEX `idx_action_type` (`action_type`)
);

DELIMITER $$

-- Trigger para auditoria de INSERT de customers
DROP TRIGGER IF EXISTS `customer_audit_after_insert`$$
CREATE TRIGGER `customer_audit_after_insert`
AFTER INSERT ON `donuts_customer`
FOR EACH ROW
BEGIN
    INSERT INTO `customer_audit_log` (
        `customer_id`, `action_type`, `new_first_name`, `new_last_name`, 
        `new_email`, `changed_by`
    ) VALUES (
        NEW.`id`, 'INSERT', NEW.`first_name`, NEW.`last_name`, 
        NEW.`email`, USER()
    );
END$$

-- Trigger para auditoria de UPDATE de customers
DROP TRIGGER IF EXISTS `customer_audit_after_update`$$
CREATE TRIGGER `customer_audit_after_update`
AFTER UPDATE ON `donuts_customer`
FOR EACH ROW
BEGIN
    INSERT INTO `customer_audit_log` (
        `customer_id`, `action_type`, 
        `old_first_name`, `new_first_name`,
        `old_last_name`, `new_last_name`,
        `old_email`, `new_email`,
        `changed_by`
    ) VALUES (
        NEW.`id`, 'UPDATE', 
        OLD.`first_name`, NEW.`first_name`,
        OLD.`last_name`, NEW.`last_name`,
        OLD.`email`, NEW.`email`,
        USER()
    );
END$$

-- Trigger para auditoria de DELETE de customers
DROP TRIGGER IF EXISTS `customer_audit_after_delete`$$
CREATE TRIGGER `customer_audit_after_delete`
AFTER DELETE ON `donuts_customer`
FOR EACH ROW
BEGIN
    INSERT INTO `customer_audit_log` (
        `customer_id`, `action_type`, 
        `old_first_name`, `old_last_name`, `old_email`, 
        `changed_by`
    ) VALUES (
        OLD.`id`, 'DELETE', 
        OLD.`first_name`, OLD.`last_name`, OLD.`email`, 
        USER()
    );
END$$

-- TRIGGER para bloquear cadastro de email duplicado
DROP TRIGGER IF EXISTS `prevent_duplicate_email_before_insert`$$
CREATE TRIGGER `prevent_duplicate_email_before_insert`
BEFORE INSERT ON `donuts_customer`
FOR EACH ROW
BEGIN
    DECLARE email_count INT;
    DECLARE existing_customer_name VARCHAR(255);
    
    -- Verificar se o email já existe
    SELECT COUNT(*), CONCAT(first_name, ' ', last_name) INTO email_count, existing_customer_name
    FROM `donuts_customer`
    WHERE `email` = NEW.`email`
    LIMIT 1;
    
    -- Se email já existe, bloquear inserção
    IF email_count > 0 THEN
        SIGNAL SQLSTATE '45000' 
        SET MESSAGE_TEXT = CONCAT('Email already registered for customer: ', IFNULL(existing_customer_name, 'Unknown'));
    END IF;
END$$

DROP TRIGGER IF EXISTS `prevent_duplicate_email_before_update`$$
CREATE TRIGGER `prevent_duplicate_email_before_update`
BEFORE UPDATE ON `donuts_customer`
FOR EACH ROW
BEGIN
    DECLARE email_count INT;
    DECLARE existing_customer_name VARCHAR(255);
    
    -- Só verificar se o email foi alterado
    IF OLD.`email` != NEW.`email` THEN
        -- Verificar se o novo email já existe em outro cliente
        SELECT COUNT(*), CONCAT(first_name, ' ', last_name) INTO email_count, existing_customer_name
        FROM `donuts_customer`
        WHERE `email` = NEW.`email` 
          AND `id` != NEW.`id`  -- Excluir o próprio cliente
        LIMIT 1;
        
        -- Se email já existe, bloquear atualização
        IF email_count > 0 THEN
            SIGNAL SQLSTATE '45000' 
            SET MESSAGE_TEXT = CONCAT('Email already registered for customer: ', IFNULL(existing_customer_name, 'Unknown'));
        END IF;
    END IF;
END$$

DELIMITER ;

-- CUSTOMER SPENDING TRACKING SYSTEM
-- Adicionar campo total_spent à tabela de customers (se não existir)
ALTER TABLE `donuts_customer` 
ADD COLUMN IF NOT EXISTS `total_spent` DECIMAL(10,2) DEFAULT 0.00;

-- Inicializar total_spent para customers existentes
UPDATE `donuts_customer` SET `total_spent` = (
    SELECT COALESCE(SUM(d.price), 0)
    FROM `donuts_review` r
    JOIN `donuts_donut` d ON r.donut_id = d.id
    WHERE r.customer_id = `donuts_customer`.id
);

DELIMITER $$

-- TRIGGER para atualizar total_spent quando uma review é adicionada (nova compra)
DROP TRIGGER IF EXISTS `update_customer_spending_after_review_insert`$$
CREATE TRIGGER `update_customer_spending_after_review_insert`
AFTER INSERT ON `donuts_review`
FOR EACH ROW
BEGIN
    DECLARE donut_price DECIMAL(10,2);
    
    -- Buscar o preço do donut avaliado
    SELECT price INTO donut_price
    FROM `donuts_donut`
    WHERE id = NEW.donut_id;
    
    -- Atualizar total gasto do cliente
    UPDATE `donuts_customer`
    SET `total_spent` = `total_spent` + donut_price
    WHERE id = NEW.customer_id;
END$$

-- TRIGGER para ajustar total_spent quando uma review é removida
DROP TRIGGER IF EXISTS `update_customer_spending_after_review_delete`$$
CREATE TRIGGER `update_customer_spending_after_review_delete`
AFTER DELETE ON `donuts_review`
FOR EACH ROW
BEGIN
    DECLARE donut_price DECIMAL(10,2);
    
    -- Buscar o preço do donut que foi removido da avaliação
    SELECT price INTO donut_price
    FROM `donuts_donut`
    WHERE id = OLD.donut_id;
    
    -- Subtrair do total gasto do cliente
    UPDATE `donuts_customer`
    SET `total_spent` = GREATEST(`total_spent` - donut_price, 0)
    WHERE id = OLD.customer_id;
END$$

-- TRIGGER para recalcular total_spent quando preço do donut muda
DROP TRIGGER IF EXISTS `recalculate_customer_spending_on_donut_price_change`$$
CREATE TRIGGER `recalculate_customer_spending_on_donut_price_change`
AFTER UPDATE ON `donuts_donut`
FOR EACH ROW
BEGIN
    DECLARE price_difference DECIMAL(10,2);
    
    -- Só executar se o preço mudou
    IF OLD.price != NEW.price THEN
        SET price_difference = NEW.price - OLD.price;
        
        -- Atualizar total_spent de todos os clientes que avaliaram este donut
        UPDATE `donuts_customer` c
        SET `total_spent` = `total_spent` + price_difference
        WHERE EXISTS (
            SELECT 1 FROM `donuts_review` r 
            WHERE r.customer_id = c.id AND r.donut_id = NEW.id
        );
    END IF;
END$$

-- TRIGGER para inicializar total_spent quando novo cliente é criado
DROP TRIGGER IF EXISTS `initialize_customer_spending_after_insert`$$
CREATE TRIGGER `initialize_customer_spending_after_insert`
AFTER INSERT ON `donuts_customer`
FOR EACH ROW
BEGIN
    -- Garantir que total_spent comece em 0 (já definido como default)
    UPDATE `donuts_customer`
    SET `total_spent` = 0.00
    WHERE id = NEW.id AND `total_spent` IS NULL;
END$$

DELIMITER ;