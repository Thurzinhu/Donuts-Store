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

-- -----------------------------------------------------------------------------
-- PROCEDURE: CriarAvaliacao
-- Descrição: Cria uma nova avaliação para um donut
-- Parâmetros:
--   - p_customer_id: ID do cliente
--   - p_donut_id: ID do donut
--   - p_rating: Nota de 1 a 5
--   - p_comment: Comentário (opcional)
-- Funcionalidade:
--   - Valida se cliente e donut existem
--   - Verifica se cliente já não avaliou o donut
--   - Cria a avaliação com data/hora atual
-- -----------------------------------------------------------------------------
CREATE PROCEDURE CriarAvaliacao(
    IN p_customer_id INT,
    IN p_donut_id INT,
    IN p_rating INT,
    IN p_comment VARCHAR(500)
)
BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    START TRANSACTION;
    
    -- Valida a nota
    IF p_rating < 1 OR p_rating > 5 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Nota deve estar entre 1 e 5';
    END IF;
    
    -- Verifica se o cliente existe
    IF NOT EXISTS (SELECT 1 FROM donuts_customer WHERE id = p_customer_id) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Cliente não encontrado';
    END IF;
    
    -- Verifica se o donut existe
    IF NOT EXISTS (SELECT 1 FROM donuts_donut WHERE id = p_donut_id) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Donut não encontrado';
    END IF;
    
    -- Verifica se cliente já avaliou este donut
    IF EXISTS (SELECT 1 FROM donuts_review WHERE customer_id = p_customer_id AND donut_id = p_donut_id) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Cliente já avaliou este donut';
    END IF;
    
    -- Cria a avaliação
    INSERT INTO donuts_review (customer_id, donut_id, rating, comment, review_date)
    VALUES (p_customer_id, p_donut_id, p_rating, p_comment, NOW());
    
    COMMIT;
    
    SELECT 'Avaliação criada com sucesso' as message, LAST_INSERT_ID() as review_id;
END$$

-- -----------------------------------------------------------------------------
-- PROCEDURE: AtualizarAvaliacao
-- Descrição: Atualiza uma avaliação existente
-- Parâmetros:
--   - p_customer_id: ID do cliente
--   - p_donut_id: ID do donut
--   - p_new_rating: Nova nota
--   - p_new_comment: Novo comentário
-- -----------------------------------------------------------------------------
CREATE PROCEDURE AtualizarAvaliacao(
    IN p_customer_id INT,
    IN p_donut_id INT,
    IN p_new_rating INT,
    IN p_new_comment VARCHAR(500)
)
BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    START TRANSACTION;
    
    -- Valida a nova nota
    IF p_new_rating < 1 OR p_new_rating > 5 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Nota deve estar entre 1 e 5';
    END IF;
    
    -- Verifica se a avaliação existe
    IF NOT EXISTS (SELECT 1 FROM donuts_review WHERE customer_id = p_customer_id AND donut_id = p_donut_id) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Avaliação não encontrada';
    END IF;
    
    -- Atualiza a avaliação
    UPDATE donuts_review 
    SET rating = p_new_rating, 
        comment = p_new_comment,
        review_date = NOW()
    WHERE customer_id = p_customer_id AND donut_id = p_donut_id;
    
    COMMIT;
    
    SELECT 'Avaliação atualizada com sucesso' as message;
END$$

-- -----------------------------------------------------------------------------
-- PROCEDURE: ObterEstatisticasDonut
-- Descrição: Retorna estatísticas completas de avaliações para um donut
-- Parâmetros:
--   - p_donut_id: ID do donut
-- Retorno: Média, total de avaliações, distribuição por notas, % satisfação
-- -----------------------------------------------------------------------------
CREATE PROCEDURE ObterEstatisticasDonut(
    IN p_donut_id INT
)
BEGIN
    -- Verifica se o donut existe
    IF NOT EXISTS (SELECT 1 FROM donuts_donut WHERE id = p_donut_id) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Donut não encontrado';
    END IF;
    
    -- Retorna estatísticas completas
    SELECT 
        d.name as donut_name,
        COALESCE(ROUND(AVG(r.rating), 2), 0) as media_avaliacoes,
        COUNT(r.id) as total_avaliacoes,
        SUM(CASE WHEN r.rating = 5 THEN 1 ELSE 0 END) as nota_5,
        SUM(CASE WHEN r.rating = 4 THEN 1 ELSE 0 END) as nota_4,
        SUM(CASE WHEN r.rating = 3 THEN 1 ELSE 0 END) as nota_3,
        SUM(CASE WHEN r.rating = 2 THEN 1 ELSE 0 END) as nota_2,
        SUM(CASE WHEN r.rating = 1 THEN 1 ELSE 0 END) as nota_1,
        COALESCE(ROUND((SUM(CASE WHEN r.rating >= 4 THEN 1 ELSE 0 END) * 100.0) / NULLIF(COUNT(r.id), 0), 2), 0) as percentual_satisfacao
    FROM donuts_donut d
    LEFT JOIN donuts_review r ON d.id = r.donut_id
    WHERE d.id = p_donut_id
    GROUP BY d.id, d.name;
END$$

-- -----------------------------------------------------------------------------
-- PROCEDURE: ObterTopDonutsAvaliados
-- Descrição: Retorna os donuts mais bem avaliados
-- Parâmetros:
--   - p_limite: Número máximo de resultados (padrão 10)
--   - p_min_avaliacoes: Mínimo de avaliações necessárias (padrão 3)
-- -----------------------------------------------------------------------------
CREATE PROCEDURE ObterTopDonutsAvaliados(
    IN p_limite INT DEFAULT 10,
    IN p_min_avaliacoes INT DEFAULT 3
)
BEGIN
    SELECT 
        d.id,
        d.name as donut_name,
        d.price,
        ROUND(AVG(r.rating), 2) as media_avaliacoes,
        COUNT(r.id) as total_avaliacoes,
        ROUND((SUM(CASE WHEN r.rating >= 4 THEN 1 ELSE 0 END) * 100.0) / COUNT(r.id), 2) as percentual_satisfacao
    FROM donuts_donut d
    INNER JOIN donuts_review r ON d.id = r.donut_id
    GROUP BY d.id, d.name, d.price
    HAVING COUNT(r.id) >= p_min_avaliacoes
    ORDER BY AVG(r.rating) DESC, COUNT(r.id) DESC
    LIMIT p_limite;
END$$

-- -----------------------------------------------------------------------------
-- PROCEDURE: ObterAvaliacoesPorCliente
-- Descrição: Retorna todas as avaliações feitas por um cliente específico
-- Parâmetros:
--   - p_customer_id: ID do cliente
-- -----------------------------------------------------------------------------
CREATE PROCEDURE ObterAvaliacoesPorCliente(
    IN p_customer_id INT
)
BEGIN
    -- Verifica se o cliente existe
    IF NOT EXISTS (SELECT 1 FROM donuts_customer WHERE id = p_customer_id) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Cliente não encontrado';
    END IF;
    
    SELECT 
        r.id as review_id,
        d.name as donut_name,
        r.rating,
        r.comment,
        r.review_date,
        CONCAT(c.first_name, ' ', c.last_name) as customer_name
    FROM donuts_review r
    INNER JOIN donuts_donut d ON r.donut_id = d.id
    INNER JOIN donuts_customer c ON r.customer_id = c.id
    WHERE r.customer_id = p_customer_id
    ORDER BY r.review_date DESC;
END$$

-- -----------------------------------------------------------------------------
-- PROCEDURE: CadastrarCliente
-- Descrição: Cadastra um novo cliente no sistema
-- Parâmetros:
--   - p_first_name: Primeiro nome do cliente
--   - p_last_name: Sobrenome do cliente
--   - p_email: Email único do cliente
-- Funcionalidade:
--   - Valida se email é único
--   - Valida formato básico dos dados
--   - Cria o cliente e retorna o ID gerado
-- -----------------------------------------------------------------------------
CREATE PROCEDURE CadastrarCliente(
    IN p_first_name VARCHAR(100),
    IN p_last_name VARCHAR(100),
    IN p_email VARCHAR(255)
)
BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    START TRANSACTION;
    
    -- Validações básicas
    IF p_first_name IS NULL OR TRIM(p_first_name) = '' THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Nome é obrigatório';
    END IF;
    
    IF p_last_name IS NULL OR TRIM(p_last_name) = '' THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Sobrenome é obrigatório';
    END IF;
    
    IF p_email IS NULL OR TRIM(p_email) = '' THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Email é obrigatório';
    END IF;
    
    -- Validação de email único
    IF EXISTS (SELECT 1 FROM donuts_customer WHERE email = p_email) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Email já está cadastrado';
    END IF;
    
    -- Cria o cliente
    INSERT INTO donuts_customer (first_name, last_name, email)
    VALUES (TRIM(p_first_name), TRIM(p_last_name), TRIM(LOWER(p_email)));
    
    COMMIT;
    
    SELECT 
        'Cliente cadastrado com sucesso' as message, 
        LAST_INSERT_ID() as customer_id,
        CONCAT(p_first_name, ' ', p_last_name) as customer_name;
END$$

-- -----------------------------------------------------------------------------
-- PROCEDURE: AtualizarCliente
-- Descrição: Atualiza dados de um cliente existente
-- Parâmetros:
--   - p_customer_id: ID do cliente
--   - p_first_name: Novo primeiro nome
--   - p_last_name: Novo sobrenome
--   - p_email: Novo email
-- -----------------------------------------------------------------------------
CREATE PROCEDURE AtualizarCliente(
    IN p_customer_id INT,
    IN p_first_name VARCHAR(100),
    IN p_last_name VARCHAR(100),
    IN p_email VARCHAR(255)
)
BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    START TRANSACTION;
    
    -- Verifica se o cliente existe
    IF NOT EXISTS (SELECT 1 FROM donuts_customer WHERE id = p_customer_id) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Cliente não encontrado';
    END IF;
    
    -- Validações básicas
    IF p_first_name IS NULL OR TRIM(p_first_name) = '' THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Nome é obrigatório';
    END IF;
    
    IF p_last_name IS NULL OR TRIM(p_last_name) = '' THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Sobrenome é obrigatório';
    END IF;
    
    IF p_email IS NULL OR TRIM(p_email) = '' THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Email é obrigatório';
    END IF;
    
    -- Verifica se email já existe (exceto para o próprio cliente)
    IF EXISTS (SELECT 1 FROM donuts_customer WHERE email = p_email AND id != p_customer_id) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Email já está em uso por outro cliente';
    END IF;
    
    -- Atualiza o cliente
    UPDATE donuts_customer 
    SET first_name = TRIM(p_first_name),
        last_name = TRIM(p_last_name),
        email = TRIM(LOWER(p_email))
    WHERE id = p_customer_id;
    
    COMMIT;
    
    SELECT 'Cliente atualizado com sucesso' as message;
END$$

-- -----------------------------------------------------------------------------
-- PROCEDURE: BuscarCliente
-- Descrição: Busca clientes por nome ou email
-- Parâmetros:
--   - p_termo_busca: Termo para buscar (nome ou email)
-- Retorno: Lista de clientes que correspondem ao termo
-- -----------------------------------------------------------------------------
CREATE PROCEDURE BuscarCliente(
    IN p_termo_busca VARCHAR(255)
)
BEGIN
    SELECT 
        id,
        first_name,
        last_name,
        email,
        CONCAT(first_name, ' ', last_name) as nome_completo
    FROM donuts_customer
    WHERE 
        LOWER(first_name) LIKE CONCAT('%', LOWER(TRIM(p_termo_busca)), '%')
        OR LOWER(last_name) LIKE CONCAT('%', LOWER(TRIM(p_termo_busca)), '%')
        OR LOWER(email) LIKE CONCAT('%', LOWER(TRIM(p_termo_busca)), '%')
        OR LOWER(CONCAT(first_name, ' ', last_name)) LIKE CONCAT('%', LOWER(TRIM(p_termo_busca)), '%')
    ORDER BY first_name, last_name;
END$$

-- -----------------------------------------------------------------------------
-- PROCEDURE: ObterClientesAtivos
-- Descrição: Retorna clientes que fizeram pedidos em um período
-- Parâmetros:
--   - p_data_inicio: Data inicial do período
--   - p_data_fim: Data final do período
-- -----------------------------------------------------------------------------
CREATE PROCEDURE ObterClientesAtivos(
    IN p_data_inicio DATE,
    IN p_data_fim DATE
)
BEGIN
    SELECT 
        c.id,
        c.first_name,
        c.last_name,
        c.email,
        COUNT(o.id) as pedidos_no_periodo,
        SUM(do.quantity) as donuts_comprados,
        SUM(p.amount_paid) as valor_gasto,
        MAX(o.timestamp) as ultimo_pedido
    FROM donuts_customer c
    INNER JOIN donuts_order o ON c.id = o.customer_id
    INNER JOIN donuts_donutorder do ON o.id = do.order_id
    INNER JOIN donuts_payment p ON o.id = p.order_id
    WHERE o.timestamp BETWEEN p_data_inicio AND p_data_fim
    GROUP BY c.id, c.first_name, c.last_name, c.email
    ORDER BY valor_gasto DESC, pedidos_no_periodo DESC;
END$$

-- -----------------------------------------------------------------------------
-- PROCEDURE: ObterTopClientes
-- Descrição: Retorna os melhores clientes por critério específico
-- Parâmetros:
--   - p_criterio: 'vendas', 'pedidos' ou 'avaliacoes'
--   - p_limite: Número máximo de resultados
-- -----------------------------------------------------------------------------
CREATE PROCEDURE ObterTopClientes(
    IN p_criterio VARCHAR(20) DEFAULT 'vendas',
    IN p_limite INT DEFAULT 10
)
BEGIN
    IF p_criterio = 'vendas' THEN
        SELECT 
            c.id,
            CONCAT(c.first_name, ' ', c.last_name) as nome_completo,
            c.email,
            COUNT(DISTINCT o.id) as total_pedidos,
            SUM(p.amount_paid) as total_gasto
        FROM donuts_customer c
        INNER JOIN donuts_order o ON c.id = o.customer_id
        INNER JOIN donuts_payment p ON o.id = p.order_id
        GROUP BY c.id, c.first_name, c.last_name, c.email
        ORDER BY total_gasto DESC
        LIMIT p_limite;
    
    ELSEIF p_criterio = 'pedidos' THEN
        SELECT 
            c.id,
            CONCAT(c.first_name, ' ', c.last_name) as nome_completo,
            c.email,
            COUNT(o.id) as total_pedidos,
            SUM(p.amount_paid) as total_gasto
        FROM donuts_customer c
        INNER JOIN donuts_order o ON c.id = o.customer_id
        INNER JOIN donuts_payment p ON o.id = p.order_id
        GROUP BY c.id, c.first_name, c.last_name, c.email
        ORDER BY total_pedidos DESC
        LIMIT p_limite;
    
    ELSEIF p_criterio = 'avaliacoes' THEN
        SELECT 
            c.id,
            CONCAT(c.first_name, ' ', c.last_name) as nome_completo,
            c.email,
            COUNT(r.id) as total_avaliacoes,
            ROUND(AVG(r.rating), 2) as media_avaliacoes
        FROM donuts_customer c
        INNER JOIN donuts_review r ON c.id = r.customer_id
        GROUP BY c.id, c.first_name, c.last_name, c.email
        ORDER BY total_avaliacoes DESC, media_avaliacoes DESC
        LIMIT p_limite;
    
    ELSE
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Critério deve ser: vendas, pedidos ou avaliacoes';
    END IF;
END$$

-- -----------------------------------------------------------------------------
-- PROCEDURE: RemoverCliente
-- Descrição: Remove um cliente e seus dados relacionados (CUIDADO!)
-- Parâmetros:
--   - p_customer_id: ID do cliente
--   - p_confirma_remocao: 'SIM' para confirmar a remoção
-- Funcionalidade:
--   - Remove avaliações, pedidos e dados do cliente
--   - Requer confirmação explícita
-- -----------------------------------------------------------------------------
CREATE PROCEDURE RemoverCliente(
    IN p_customer_id INT,
    IN p_confirma_remocao VARCHAR(3)
)
BEGIN
    DECLARE v_customer_name VARCHAR(255);
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    -- Verifica confirmação
    IF UPPER(p_confirma_remocao) != 'SIM' THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Confirmação necessária: use "SIM" para confirmar';
    END IF;

    START TRANSACTION;
    
    -- Verifica se o cliente existe e obtém o nome
    SELECT CONCAT(first_name, ' ', last_name)
    INTO v_customer_name
    FROM donuts_customer 
    WHERE id = p_customer_id;
    
    IF v_customer_name IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Cliente não encontrado';
    END IF;
    
    -- Remove dados relacionados (devido às foreign keys)
    -- Nota: Dependendo da configuração das FKs, pode dar erro
    -- Esta procedure assume CASCADE DELETE ou remoção manual
    
    DELETE FROM donuts_review WHERE customer_id = p_customer_id;
    DELETE FROM donuts_payment WHERE order_id IN (SELECT id FROM donuts_order WHERE customer_id = p_customer_id);
    DELETE FROM donuts_donutorder WHERE order_id IN (SELECT id FROM donuts_order WHERE customer_id = p_customer_id);
    DELETE FROM donuts_order WHERE customer_id = p_customer_id;
    DELETE FROM donuts_customer WHERE id = p_customer_id;
    
    COMMIT;
    
    SELECT 
        'Cliente removido com sucesso' as message,
        v_customer_name as cliente_removido;
END$$

-- -----------------------------------------------------------------------------
-- PROCEDURE: CadastrarFuncionario
-- Descrição: Cadastra um novo funcionário no sistema
-- Parâmetros:
--   - p_name: Nome completo do funcionário
--   - p_role: Cargo/função do funcionário
--   - p_hire_date: Data de contratação
--   - p_salary: Salário do funcionário
-- Funcionalidade:
--   - Valida dados obrigatórios
--   - Valida salário positivo
--   - Cria o funcionário e retorna o ID gerado
-- -----------------------------------------------------------------------------
CREATE PROCEDURE CadastrarFuncionario(
    IN p_name VARCHAR(100),
    IN p_role VARCHAR(100),
    IN p_hire_date DATE,
    IN p_salary DECIMAL(10,2)
)
BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    START TRANSACTION;
    
    -- Validações básicas
    IF p_name IS NULL OR TRIM(p_name) = '' THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Nome é obrigatório';
    END IF;
    
    IF p_role IS NULL OR TRIM(p_role) = '' THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Cargo é obrigatório';
    END IF;
    
    IF p_hire_date IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Data de contratação é obrigatória';
    END IF;
    
    IF p_salary IS NULL OR p_salary <= 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Salário deve ser maior que zero';
    END IF;
    
    -- Valida data de contratação (não pode ser futura)
    IF p_hire_date > CURDATE() THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Data de contratação não pode ser futura';
    END IF;
    
    -- Cria o funcionário
    INSERT INTO donuts_employee (name, role, hire_date, salary)
    VALUES (TRIM(p_name), TRIM(p_role), p_hire_date, p_salary);
    
    COMMIT;
    
    SELECT 
        'Funcionário cadastrado com sucesso' as message, 
        LAST_INSERT_ID() as employee_id,
        p_name as employee_name,
        p_role as employee_role;
END$$

-- -----------------------------------------------------------------------------
-- PROCEDURE: AtualizarFuncionario
-- Descrição: Atualiza dados de um funcionário existente
-- Parâmetros:
--   - p_employee_id: ID do funcionário
--   - p_name: Novo nome
--   - p_role: Novo cargo
--   - p_salary: Novo salário
-- Nota: Data de contratação não é alterável por esta procedure
-- -----------------------------------------------------------------------------
CREATE PROCEDURE AtualizarFuncionario(
    IN p_employee_id INT,
    IN p_name VARCHAR(100),
    IN p_role VARCHAR(100),
    IN p_salary DECIMAL(10,2)
)
BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    START TRANSACTION;
    
    -- Verifica se o funcionário existe
    IF NOT EXISTS (SELECT 1 FROM donuts_employee WHERE id = p_employee_id) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Funcionário não encontrado';
    END IF;
    
    -- Validações básicas
    IF p_name IS NULL OR TRIM(p_name) = '' THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Nome é obrigatório';
    END IF;
    
    IF p_role IS NULL OR TRIM(p_role) = '' THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Cargo é obrigatório';
    END IF;
    
    IF p_salary IS NULL OR p_salary <= 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Salário deve ser maior que zero';
    END IF;
    
    -- Atualiza o funcionário
    UPDATE donuts_employee 
    SET name = TRIM(p_name),
        role = TRIM(p_role),
        salary = p_salary
    WHERE id = p_employee_id;
    
    COMMIT;
    
    SELECT 'Funcionário atualizado com sucesso' as message;
END$$

-- -----------------------------------------------------------------------------
-- PROCEDURE: AjustarSalario
-- Descrição: Ajusta o salário de um funcionário (aumento/desconto)
-- Parâmetros:
--   - p_employee_id: ID do funcionário
--   - p_tipo_ajuste: 'PERCENTUAL' ou 'VALOR'
--   - p_valor_ajuste: Valor do ajuste (% ou valor absoluto)
--   - p_motivo: Motivo do ajuste (opcional)
-- -----------------------------------------------------------------------------
CREATE PROCEDURE AjustarSalario(
    IN p_employee_id INT,
    IN p_tipo_ajuste VARCHAR(10),
    IN p_valor_ajuste DECIMAL(10,2),
    IN p_motivo VARCHAR(255)
)
BEGIN
    DECLARE v_salario_atual DECIMAL(10,2);
    DECLARE v_novo_salario DECIMAL(10,2);
    DECLARE v_employee_name VARCHAR(100);
    
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    START TRANSACTION;
    
    -- Obtém dados atuais do funcionário
    SELECT salary, name
    INTO v_salario_atual, v_employee_name
    FROM donuts_employee 
    WHERE id = p_employee_id;
    
    IF v_salario_atual IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Funcionário não encontrado';
    END IF;
    
    -- Calcula novo salário baseado no tipo de ajuste
    IF UPPER(p_tipo_ajuste) = 'PERCENTUAL' THEN
        SET v_novo_salario = v_salario_atual * (1 + (p_valor_ajuste / 100));
    ELSEIF UPPER(p_tipo_ajuste) = 'VALOR' THEN
        SET v_novo_salario = v_salario_atual + p_valor_ajuste;
    ELSE
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Tipo de ajuste deve ser PERCENTUAL ou VALOR';
    END IF;
    
    -- Valida se o novo salário é positivo
    IF v_novo_salario <= 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Novo salário deve ser maior que zero';
    END IF;
    
    -- Atualiza o salário
    UPDATE donuts_employee 
    SET salary = v_novo_salario
    WHERE id = p_employee_id;
    
    COMMIT;
    
    SELECT 
        'Salário ajustado com sucesso' as message,
        v_employee_name as funcionario,
        v_salario_atual as salario_anterior,
        v_novo_salario as novo_salario,
        ROUND(((v_novo_salario - v_salario_atual) / v_salario_atual) * 100, 2) as percentual_ajuste,
        COALESCE(p_motivo, 'Não informado') as motivo;
END$$

-- -----------------------------------------------------------------------------
-- PROCEDURE: BuscarFuncionario
-- Descrição: Busca funcionários por nome ou cargo
-- Parâmetros:
--   - p_termo_busca: Termo para buscar (nome ou cargo)
-- Retorno: Lista de funcionários que correspondem ao termo
-- -----------------------------------------------------------------------------
CREATE PROCEDURE BuscarFuncionario(
    IN p_termo_busca VARCHAR(255)
)
BEGIN
    SELECT 
        id,
        name,
        role,
        hire_date,
        salary,
        DATEDIFF(CURDATE(), hire_date) as dias_na_empresa,
        FLOOR(DATEDIFF(CURDATE(), hire_date) / 365) as anos_na_empresa
    FROM donuts_employee
    WHERE 
        LOWER(name) LIKE CONCAT('%', LOWER(TRIM(p_termo_busca)), '%')
        OR LOWER(role) LIKE CONCAT('%', LOWER(TRIM(p_termo_busca)), '%')
    ORDER BY name;
END$$

-- -----------------------------------------------------------------------------
-- PROCEDURE: ObterTopVendedores
-- Descrição: Ranking dos funcionários por vendas
-- Parâmetros:
--   - p_periodo_dias: Período em dias (padrão 30)
--   - p_limite: Número máximo de resultados (padrão 10)
-- -----------------------------------------------------------------------------
CREATE PROCEDURE ObterTopVendedores(
    IN p_periodo_dias INT DEFAULT 30,
    IN p_limite INT DEFAULT 10
)
BEGIN
    SELECT 
        e.id,
        e.name as funcionario,
        e.role as cargo,
        COUNT(DISTINCT o.id) as pedidos_atendidos,
        SUM(do.quantity) as donuts_vendidos,
        SUM(p.amount_paid) as valor_total_vendas,
        ROUND(SUM(p.amount_paid) / COUNT(DISTINCT o.id), 2) as ticket_medio
    FROM donuts_employee e
    INNER JOIN donuts_order o ON e.id = o.employee_id
    INNER JOIN donuts_donutorder do ON o.id = do.order_id
    INNER JOIN donuts_payment p ON o.id = p.order_id
    WHERE o.timestamp >= DATE_SUB(CURDATE(), INTERVAL p_periodo_dias DAY)
    GROUP BY e.id, e.name, e.role
    ORDER BY valor_total_vendas DESC, pedidos_atendidos DESC
    LIMIT p_limite;
END$$

