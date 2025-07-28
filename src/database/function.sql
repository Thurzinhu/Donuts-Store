-- -----------------------------------------------------------------------------
-- FUNCTION: CalcularCustoReceita
-- Descrição: Calcula o custo total dos ingredientes para uma receita de donut
-- Parâmetros:
--   - p_donut_id: ID do donut para calcular o custo
-- Retorno: Valor decimal com o custo total dos ingredientes
-- Funcionalidade:
--   - Soma o custo de todos os ingredientes usados na receita
--   - Considera a quantidade de cada ingrediente
--   - Retorna 0 se o donut não tiver receita cadastrada
-- -----------------------------------------------------------------------------
DELIMITER $$

CREATE FUNCTION CalcularCustoReceita(p_donut_id INT)
RETURNS DECIMAL(10,2)
READS SQL DATA
DETERMINISTIC
BEGIN
    DECLARE v_custo_total DECIMAL(10,2) DEFAULT 0.00;
    
    -- Verifica se o donut existe
    IF NOT EXISTS (SELECT 1 FROM donuts_donut WHERE id = p_donut_id) THEN
        RETURN 0.00;
    END IF;
    
    -- Calcula o custo total da receita
    -- Multiplica a quantidade de cada ingrediente pelo seu preço por unidade
    SELECT COALESCE(SUM(r.quantity * i.price_per_unit), 0.00)
    INTO v_custo_total
    FROM donuts_recipe r
    INNER JOIN donuts_ingredient i ON r.ingredient_id = i.id
    WHERE r.donut_id = p_donut_id;
    
    RETURN v_custo_total;
    
END$$

-- -----------------------------------------------------------------------------
-- FUNCTION: CalcularMediaAvaliacoes
-- Descrição: Calcula a média das avaliações para um donut específico
-- Parâmetros:
--   - p_donut_id: ID do donut para calcular a média
-- Retorno: Valor decimal com a média das avaliações (1-5)
-- Funcionalidade:
--   - Calcula a média aritmética das avaliações
--   - Retorna NULL se não houver avaliações
-- -----------------------------------------------------------------------------
CREATE FUNCTION CalcularMediaAvaliacoes(p_donut_id INT)
RETURNS DECIMAL(3,2)
READS SQL DATA
DETERMINISTIC
BEGIN
    DECLARE v_media DECIMAL(3,2);
    
    -- Verifica se o donut existe
    IF NOT EXISTS (SELECT 1 FROM donuts_donut WHERE id = p_donut_id) THEN
        RETURN NULL;
    END IF;
    
    -- Calcula a média das avaliações
    SELECT AVG(rating)
    INTO v_media
    FROM donuts_review
    WHERE donut_id = p_donut_id;
    
    RETURN v_media;
END$$

-- -----------------------------------------------------------------------------
-- FUNCTION: ContarAvaliacoesPorNota
-- Descrição: Conta quantas avaliações um donut tem para uma nota específica
-- Parâmetros:
--   - p_donut_id: ID do donut
--   - p_rating: Nota específica (1-5)
-- Retorno: Número inteiro com a contagem
-- -----------------------------------------------------------------------------
CREATE FUNCTION ContarAvaliacoesPorNota(p_donut_id INT, p_rating INT)
RETURNS INT
READS SQL DATA
DETERMINISTIC
BEGIN
    DECLARE v_count INT DEFAULT 0;
    
    -- Valida os parâmetros
    IF p_rating < 1 OR p_rating > 5 THEN
        RETURN 0;
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM donuts_donut WHERE id = p_donut_id) THEN
        RETURN 0;
    END IF;
    
    -- Conta as avaliações com a nota específica
    SELECT COUNT(*)
    INTO v_count
    FROM donuts_review
    WHERE donut_id = p_donut_id AND rating = p_rating;
    
    RETURN v_count;
END$$

-- -----------------------------------------------------------------------------
-- FUNCTION: ObterMelhorDonut
-- Descrição: Retorna o ID do donut com a melhor média de avaliações
-- Parâmetros: Nenhum
-- Retorno: ID do donut com melhor média (ou NULL se não houver reviews)
-- Funcionalidade:
--   - Considera apenas donuts com pelo menos 3 avaliações
--   - Retorna o donut com maior média
-- -----------------------------------------------------------------------------
CREATE FUNCTION ObterMelhorDonut()
RETURNS INT
READS SQL DATA
DETERMINISTIC
BEGIN
    DECLARE v_donut_id INT;
    
    SELECT donut_id
    INTO v_donut_id
    FROM donuts_review
    GROUP BY donut_id
    HAVING COUNT(*) >= 3
    ORDER BY AVG(rating) DESC, COUNT(*) DESC
    LIMIT 1;
    
    RETURN v_donut_id;
END$$

-- -----------------------------------------------------------------------------
-- FUNCTION: CalcularPercentualSatisfacao
-- Descrição: Calcula o percentual de satisfação (avaliações 4 e 5) para um donut
-- Parâmetros:
--   - p_donut_id: ID do donut
-- Retorno: Percentual de 0 a 100
-- -----------------------------------------------------------------------------
CREATE FUNCTION CalcularPercentualSatisfacao(p_donut_id INT)
RETURNS DECIMAL(5,2)
READS SQL DATA
DETERMINISTIC
BEGIN
    DECLARE v_total_reviews INT DEFAULT 0;
    DECLARE v_positive_reviews INT DEFAULT 0;
    DECLARE v_percentual DECIMAL(5,2);
    
    -- Verifica se o donut existe
    IF NOT EXISTS (SELECT 1 FROM donuts_donut WHERE id = p_donut_id) THEN
        RETURN 0.00;
    END IF;
    
    -- Conta total de reviews
    SELECT COUNT(*)
    INTO v_total_reviews
    FROM donuts_review
    WHERE donut_id = p_donut_id;
    
    -- Se não há reviews, retorna 0
    IF v_total_reviews = 0 THEN
        RETURN 0.00;
    END IF;
    
    -- Conta reviews positivas (4 e 5 estrelas)
    SELECT COUNT(*)
    INTO v_positive_reviews
    FROM donuts_review
    WHERE donut_id = p_donut_id AND rating >= 4;
    
    -- Calcula o percentual
    SET v_percentual = (v_positive_reviews * 100.0) / v_total_reviews;
    
    RETURN v_percentual;
END$$


DELIMITER ;

-- Função para calcular quantos dias se passaram desde a última review do cliente
DELIMITER $$
CREATE FUNCTION days_since_last_review(customer_id INT) 
RETURNS INT
READS SQL DATA
DETERMINISTIC
BEGIN
    DECLARE days_since INT DEFAULT -1;
    
    SELECT DATEDIFF(CURDATE(), MAX(review_date)) INTO days_since
    FROM donuts_review
    WHERE customer_id = customer_id;
    
    RETURN COALESCE(days_since, -1);
END$$
DELIMITER ;


-- Função para estimar quanto o cliente gastou baseado nos donuts que avaliou
DELIMITER $$
CREATE FUNCTION customer_spending_estimate(customer_id INT) 
RETURNS DECIMAL(10,2)
READS SQL DATA
DETERMINISTIC
BEGIN
    DECLARE total_spent DECIMAL(10,2) DEFAULT 0;
    
    SELECT COALESCE(SUM(d.price), 0) INTO total_spent
    FROM donuts_review r
    JOIN donuts_donut d ON r.donut_id = d.id
    WHERE r.customer_id = customer_id;
    
    RETURN total_spent;
END$$
DELIMITER ;


-- Função para calcular a frequência média de reviews (reviews por mês)
DELIMITER $$
CREATE FUNCTION customer_review_frequency(customer_id INT) 
RETURNS DECIMAL(5,2)
READS SQL DATA
DETERMINISTIC
BEGIN
    DECLARE frequency_rate DECIMAL(5,2) DEFAULT 0;
    DECLARE review_count INT DEFAULT 0;
    DECLARE months_active INT DEFAULT 0;
    
    SELECT COUNT(*) INTO review_count
    FROM donuts_review
    WHERE customer_id = customer_id;
    
    SELECT COALESCE(CEIL(DATEDIFF(CURDATE(), MIN(review_date)) / 30), 1) INTO months_active
    FROM donuts_review
    WHERE customer_id = customer_id;
    
    SET frequency_rate = review_count / months_active;
    
    RETURN frequency_rate;
END$$
DELIMITER ;


-- Função para calcular o custo total anual incluindo encargos estimados
DELIMITER $$
CREATE FUNCTION calculate_employee_annual_cost(employee_id INT) 
RETURNS DECIMAL(12,2)
READS SQL DATA
DETERMINISTIC
BEGIN
    DECLARE annual_cost DECIMAL(12,2) DEFAULT 0;
    DECLARE monthly_salary DECIMAL(10,2) DEFAULT 0;
    
    SELECT salary INTO monthly_salary
    FROM donuts_employee WHERE id = employee_id;
    
    -- Custo anual = salário * 12 + encargos (estimativa de 33%)
    SET annual_cost = (monthly_salary * 12) * 1.33;
    
    RETURN annual_cost;
END$$
DELIMITER ;


-- Função para classificar funcionário baseado no salário relativo ao cargo
DELIMITER $$
CREATE FUNCTION employee_performance_tier(employee_id INT) 
RETURNS VARCHAR(20)
READS SQL DATA
DETERMINISTIC
BEGIN
    DECLARE tier VARCHAR(20);
    DECLARE emp_salary DECIMAL(10,2) DEFAULT 0;
    DECLARE emp_role VARCHAR(100);
    DECLARE avg_salary DECIMAL(10,2) DEFAULT 0;
    
    SELECT salary, role INTO emp_salary, emp_role
    FROM donuts_employee WHERE id = employee_id;
    
    SELECT AVG(salary) INTO avg_salary
    FROM donuts_employee WHERE role = emp_role;
    
    CASE 
        WHEN emp_salary > avg_salary * 1.2 THEN SET tier = 'High Performer';
        WHEN emp_salary > avg_salary * 1.1 THEN SET tier = 'Above Average';
        WHEN emp_salary < avg_salary * 0.9 THEN SET tier = 'Entry Level';
        ELSE SET tier = 'Standard';
    END CASE;
    
    RETURN tier;
END$$
DELIMITER ;


-- Função para calcular quantos dias faltam para o próximo aniversário de contratação
DELIMITER $$
CREATE FUNCTION employee_next_anniversary(employee_id INT) 
RETURNS INT
READS SQL DATA
DETERMINISTIC
BEGIN
    DECLARE days_to_anniversary INT DEFAULT 0;
    DECLARE hire_date_this_year DATE;
    DECLARE hire_date_next_year DATE;
    DECLARE original_hire_date DATE;
    
    SELECT hire_date INTO original_hire_date
    FROM donuts_employee WHERE id = employee_id;
    
    -- Aniversário neste ano
    SET hire_date_this_year = DATE(CONCAT(YEAR(CURDATE()), '-', 
                                         LPAD(MONTH(original_hire_date), 2, '0'), '-', 
                                         LPAD(DAY(original_hire_date), 2, '0')));
    
    -- Se já passou este ano, calcular para o próximo
    IF hire_date_this_year < CURDATE() THEN
        SET hire_date_next_year = DATE_ADD(hire_date_this_year, INTERVAL 1 YEAR);
        SET days_to_anniversary = DATEDIFF(hire_date_next_year, CURDATE());
    ELSE
        SET days_to_anniversary = DATEDIFF(hire_date_this_year, CURDATE());
    END IF;
    
    RETURN days_to_anniversary;
END$$
DELIMITER ;