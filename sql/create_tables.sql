CREATE SCHEMA IF NOT EXISTS bi;
SET search_path TO bi;

CREATE TABLE products (
    artikul VARCHAR(50) PRIMARY KEY,
    category VARCHAR(100) NOT NULL,
    price NUMERIC(12,2) NOT NULL
);

CREATE TABLE clients (
    client_id SERIAL PRIMARY KEY,
    company_name VARCHAR(255) NOT NULL,
    inn VARCHAR(12) UNIQUE NOT NULL,
    manager_id INTEGER NOT NULL
);


CREATE TABLE orders (
    order_id SERIAL PRIMARY KEY,
    client_id INTEGER NOT NULL REFERENCES clients(client_id),
    created_at DATE NOT NULL
);

CREATE TABLE order_items (
    order_item_id SERIAL PRIMARY KEY,
    order_id INTEGER NOT NULL REFERENCES orders(order_id) ON DELETE CASCADE,
    artikul VARCHAR(50) NOT NULL REFERENCES products(artikul),
    item_amount NUMERIC(12,2) NOT NULL,
    item_margin NUMERIC(12,2)
);

CREATE TABLE realizations (
    realization_id SERIAL PRIMARY KEY,
    order_item_id INTEGER NOT NULL REFERENCES order_items(order_item_id) ON DELETE CASCADE,
    sale_date DATE NOT NULL,
    sale_amount NUMERIC(12,2) NOT NULL
);


CREATE TABLE returns (
    return_id SERIAL PRIMARY KEY,
    realization_id INTEGER NOT NULL REFERENCES realizations(realization_id) ON DELETE CASCADE,
    return_amount NUMERIC(12,2) NOT NULL,
    return_date DATE NOT NULL
);

CREATE TABLE planned_metrics (
    id SERIAL PRIMARY KEY,
    manager_id INTEGER NOT NULL,
    period_start DATE NOT NULL,
    period_end DATE NOT NULL,
    planned_revenue NUMERIC(14,2),
    planned_margin NUMERIC(14,2),
    planned_avg_check NUMERIC(14,2)
);

CREATE TABLE teams (
    team_id SERIAL PRIMARY KEY,
    team_name VARCHAR(100) NOT NULL,
    leader_id INTEGER NOT NULL
);


CREATE TABLE team_members (
    team_id INTEGER NOT NULL REFERENCES teams(team_id) ON DELETE CASCADE,
    manager_id INTEGER NOT NULL,
    role_in_team VARCHAR(50),
    PRIMARY KEY (team_id, manager_id)
);
