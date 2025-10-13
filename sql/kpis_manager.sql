-- Выручка по дням

SELECT
    DATE(rz.sale_date) AS "Дата",
    p.category AS "Продуктовая категория::multi-filter",
    c.manager_id,
    SUM(rz.sale_amount - COALESCE(rt.return_amount, 0)) AS "Дневная выручка"
FROM bi.realizations rz
LEFT JOIN bi.returns rt 
    ON rt.realization_id = rz.realization_id
JOIN bi.order_items oi 
    ON oi.order_item_id = rz.order_item_id
JOIN bi.products p 
    ON p.artikul = oi.artikul
JOIN bi.orders o 
    ON o.order_id = oi.order_id
JOIN bi.clients c 
    ON c.client_id = o.client_id
WHERE c.manager_id IN ({{ manager_id }})
GROUP BY DATE(rz.sale_date), p.category, c.manager_id
ORDER BY "Дата", p.category, c.manager_id;

-- Топ-10 клиентов по прибыли (марже)

SELECT
    c.company_name AS "Клиент",
    SUM(oi.item_margin) AS "Total маржа"
FROM bi.clients c
JOIN bi.orders o ON o.client_id = c.client_id
JOIN bi.order_items oi ON oi.order_id = o.order_id
GROUP BY "Клиент"
ORDER BY "Total маржа" DESC
LIMIT 10;

-- Самые прибыльные категории товаров

SELECT
    p.category,
    SUM(oi.item_margin) AS "Total маржа"
FROM bi.products p
JOIN bi.order_items oi ON oi.artikul = p.artikul
GROUP BY p.category
ORDER BY "Total маржа" DESC;

-- Сравнение с плановыми показателями

WITH fact AS (
    SELECT
        c.manager_id,
        DATE_TRUNC('month', rz.sale_date) AS month,
        SUM(rz.sale_amount - COALESCE(rt.return_amount, 0)) AS fact_revenue,
        SUM(oi.item_margin) AS fact_margin,
        ROUND(SUM(rz.sale_amount - COALESCE(rt.return_amount, 0)) / NULLIF(COUNT(DISTINCT o.order_id), 0), 2) AS fact_avg_check
    FROM bi.clients c
    JOIN bi.orders o ON o.client_id = c.client_id
    JOIN bi.order_items oi ON oi.order_id = o.order_id
    LEFT JOIN bi.realizations rz ON rz.order_item_id = oi.order_item_id
    LEFT JOIN bi.returns rt ON rt.realization_id = rz.realization_id
    GROUP BY c.manager_id, DATE_TRUNC('month', rz.sale_date)
)
SELECT
    f.manager_id,
    f.month,
    f.fact_revenue,
    f.fact_margin,
    f.fact_avg_check AS "Средний чек факт" ,
    pm.planned_revenue,
    pm.planned_margin,
    pm.planned_avg_check AS "Средний чек план",
    ROUND(f.fact_revenue / NULLIF(pm.planned_revenue, 0) * 100, 1) AS revenue_plan_achievement_pct,
    ROUND(f.fact_margin / NULLIF(pm.planned_margin, 0) * 100, 1) AS margin_plan_achievement_pct
FROM fact f
LEFT JOIN bi.planned_metrics pm
  ON f.manager_id = pm.manager_id
  AND f.month BETWEEN pm.period_start AND pm.period_end
WHERE f.manager_id IN ({{ manager_id }})
ORDER BY f.manager_id, f.month;

-- Total KPI

SELECT
    SUM(fact_revenue) AS total_fact_revenue,
    SUM(fact_margin) AS total_fact_margin,
    SUM(planned_revenue) AS total_planned_revenue,
    SUM(planned_margin) AS total_planned_margin,
    AVG(revenue_plan_achievement_pct) AS total_revenue_plan_achievement_pct,
    AVG(margin_plan_achievement_pct) AS total_margin_plan_achievement_pct
FROM query_14
WHERE manager_id IN ({{ manager_id }})

-- Продажи по артикулу

SELECT
  c.client_id,
  c.company_name AS "Клиент",
  oi.artikul AS "Артикул" ,
  p.category AS "Категория",
  SUM(rz.sale_amount - COALESCE(rt.return_amount, 0)) AS "Выручка",
  SUM(oi.item_margin) AS "Маржа"
FROM
  bi.clients c
  JOIN bi.orders o ON o.client_id = c.client_id
  JOIN bi.order_items oi ON oi.order_id = o.order_id
  JOIN bi.products p ON p.artikul = oi.artikul
  LEFT JOIN bi.realizations rz ON rz.order_item_id = oi.order_item_id
  LEFT JOIN bi.returns rt ON rt.realization_id = rz.realization_id
WHERE oi.artikul IN ({{ artikul }})
GROUP BY
  c.client_id,
  c.company_name,
  oi.artikul,
  p.category
ORDER BY
  "Выручка" DESC;
