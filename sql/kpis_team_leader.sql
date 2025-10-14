-- Показатели по командам

SELECT
    t.team_name AS "Название команды",
    SUM(rz.sale_amount - COALESCE(rt.return_amount, 0)) AS "Факт выручка",
    SUM(oi.item_margin) AS "Факт маржа",
    SUM(pm.planned_revenue) AS "План выручка",
    SUM(pm.planned_margin) AS "План маржа"
FROM bi.teams t
JOIN bi.team_members tm 
    ON tm.team_id = t.team_id
JOIN bi.clients c 
    ON c.manager_id = tm.manager_id
JOIN bi.orders o 
    ON o.client_id = c.client_id
JOIN bi.order_items oi 
    ON oi.order_id = o.order_id
JOIN bi.realizations rz 
    ON rz.order_item_id = oi.order_item_id
LEFT JOIN bi.returns rt 
    ON rt.realization_id = rz.realization_id
LEFT JOIN bi.planned_metrics pm 
    ON pm.manager_id = tm.manager_id
    AND rz.sale_date BETWEEN pm.period_start AND pm.period_end
WHERE t.team_name IN ({{ team_name }})
GROUP BY t.team_name
ORDER BY "Факт выручка" DESC;

-- Выполнение плана

SELECT
    c.manager_id AS "ID менеджера",
    SUM(rz.sale_amount - COALESCE(rt.return_amount, 0)) AS "Факт выручка",
    SUM(oi.item_margin) AS "Факт маржа",
    COALESCE(SUM(DISTINCT pm.planned_revenue), 0) AS "План выручка",
    COALESCE(SUM(DISTINCT pm.planned_margin), 0) AS "План маржа",
    ROUND(
        CASE 
            WHEN SUM(DISTINCT pm.planned_revenue) = 0 THEN NULL
            ELSE (SUM(rz.sale_amount - COALESCE(rt.return_amount, 0)) / SUM(DISTINCT pm.planned_revenue) * 100)
        END, 2
    ) AS "Выполнение плана по выручке, %",
    ROUND(
        CASE 
            WHEN SUM(DISTINCT pm.planned_margin) = 0 THEN NULL
            ELSE (SUM(oi.item_margin) / SUM(DISTINCT pm.planned_margin) * 100)
        END, 2
    ) AS "Выполнение плана по марже, %"
FROM bi.clients c
JOIN bi.orders o 
    ON o.client_id = c.client_id
JOIN bi.order_items oi 
    ON oi.order_id = o.order_id
JOIN bi.realizations rz 
    ON rz.order_item_id = oi.order_item_id
LEFT JOIN bi.returns rt 
    ON rt.realization_id = rz.realization_id
LEFT JOIN bi.planned_metrics pm 
    ON pm.manager_id = c.manager_id
    AND rz.sale_date BETWEEN pm.period_start AND pm.period_end
GROUP BY c.manager_id
ORDER BY c.manager_id;

-- KPI

SELECT
    SUM(fact_revenue) AS total_fact_revenue,
    SUM(fact_margin) AS total_fact_margin,
    SUM(planned_revenue) AS total_planned_revenue,
    SUM(planned_margin) AS total_planned_margin,
    AVG(revenue_plan_achievement_pct) AS total_revenue_plan_achievement_pct,
    AVG(margin_plan_achievement_pct) AS total_margin_plan_achievement_pct,
    AVG(fact_avg_check) AS total_fact_avg_check,
    AVG(planned_avg_check) AS total_planned_avg_check,
    ROUND(AVG(fact_avg_check) / NULLIF(AVG(planned_avg_check), 0) * 100, 1) AS total_avg_check_pct
FROM query_14
WHERE manager_id IN ({{ manager_id }})

-- Drill-down

SELECT
    t.team_name AS "Команда",
    tm.manager_id AS "ID менеджера",
    c.company_name AS "Клиент",
    SUM(rz.sale_amount - COALESCE(rt.return_amount, 0)) AS "Выручка",
    SUM(
        CASE 
            WHEN COALESCE(rt.return_amount, 0) >= rz.sale_amount THEN 0
            WHEN COALESCE(rt.return_amount, 0) > 0 THEN 
                oi.item_margin * (1 - (rt.return_amount / rz.sale_amount))
            ELSE 
                oi.item_margin
        END
    ) AS "Маржа"
FROM bi.teams t
JOIN bi.team_members tm 
    ON tm.team_id = t.team_id
JOIN bi.clients c 
    ON c.manager_id = tm.manager_id
JOIN bi.orders o 
    ON o.client_id = c.client_id
JOIN bi.order_items oi 
    ON oi.order_id = o.order_id
JOIN bi.realizations rz 
    ON rz.order_item_id = oi.order_item_id
LEFT JOIN bi.returns rt 
    ON rt.realization_id = rz.realization_id
WHERE t.team_name IN ({{ team_name }})
GROUP BY 
    t.team_name,
    tm.manager_id,
    c.company_name
ORDER BY 
    t.team_name,
    tm.manager_id,
    "Выручка" DESC;
