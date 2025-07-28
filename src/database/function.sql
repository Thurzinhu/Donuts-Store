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

DELIMITER ;