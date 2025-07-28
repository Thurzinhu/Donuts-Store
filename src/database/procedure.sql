-- =============================================================================
-- PROCEDURES E FUNCTIONS PARA O SISTEMA DONUTS STORE
-- =============================================================================

-- -----------------------------------------------------------------------------
-- PROCEDURE: ProcessarPedido
-- Descrição: Processa um pedido completo, criando o pedido e seus itens
-- Parâmetros:
--   - p_order_number: Número único do pedido
--   - p_customer_id: ID do cliente
--   - p_employee_id: ID do funcionário responsável
--   - p_order_date: Data do pedido
-- Funcionalidade:
--   - Cria um novo pedido na tabela Order
--   - Retorna o ID do pedido criado para uso posterior
-- -----------------------------------------------------------------------------
DELIMITER $$

CREATE PROCEDURE ProcessarPedido(
    IN p_order_number BIGINT,
    IN p_customer_id INT,
    IN p_employee_id BIGINT,
    IN p_order_date DATE
)
BEGIN
    DECLARE v_order_id INT;
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    -- Inicia transação para garantir consistência
    START TRANSACTION;
    
    -- Verifica se o número do pedido já existe
    IF EXISTS (SELECT 1 FROM `Order` WHERE order_number = p_order_number) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Número de pedido já existe';
    END IF;
    
    -- Verifica se o cliente existe
    IF NOT EXISTS (SELECT 1 FROM donuts_customer WHERE id = p_customer_id) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Cliente não encontrado';
    END IF;
    
    -- Verifica se o funcionário existe
    IF NOT EXISTS (SELECT 1 FROM donuts_employee WHERE id = p_employee_id) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Funcionário não encontrado';
    END IF;
    
    -- Cria o pedido
    INSERT INTO `Order` (order_number, customer_id, timestamp, employee_id)
    VALUES (p_order_number, p_customer_id, p_order_date, p_employee_id);
    
    -- Obtém o ID do pedido criado
    SET v_order_id = LAST_INSERT_ID();
    
    -- Confirma a transação
    COMMIT;
    
    -- Retorna informações do pedido criado
    SELECT 
        v_order_id as order_id,
        p_order_number as order_number,
        'Pedido processado com sucesso' as message;
        
END$$

DELIMITER ;