-- =============================================================================
-- Online Mobile Shopping Database
-- Database: mobile_store_db
-- =============================================================================

-- -----------------------------------------------------------------------------
-- 1. Create and use database
-- -----------------------------------------------------------------------------
DROP DATABASE IF EXISTS mobile_store_db;
CREATE DATABASE mobile_store_db
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;

USE mobile_store_db;

-- -----------------------------------------------------------------------------
-- 2. Tables (primary keys, foreign keys, NOT NULL, UNIQUE)
-- -----------------------------------------------------------------------------

CREATE TABLE Customers (
  customer_id INT UNSIGNED NOT NULL AUTO_INCREMENT,
  name        VARCHAR(120) NOT NULL,
  email       VARCHAR(180) NOT NULL,
  phone       VARCHAR(32)  NOT NULL,
  address     VARCHAR(255) NOT NULL,
  PRIMARY KEY (customer_id),
  UNIQUE KEY uq_customers_email (email)
) ENGINE=InnoDB;

CREATE TABLE Mobiles (
  mobile_id INT UNSIGNED NOT NULL AUTO_INCREMENT,
  brand     VARCHAR(80)  NOT NULL,
  model     VARCHAR(120) NOT NULL,
  price     DECIMAL(12, 2) NOT NULL,
  stock     INT UNSIGNED NOT NULL DEFAULT 0,
  PRIMARY KEY (mobile_id),
  UNIQUE KEY uq_mobiles_brand_model (brand, model)
) ENGINE=InnoDB;

CREATE TABLE Orders (
  order_id     INT UNSIGNED NOT NULL AUTO_INCREMENT,
  customer_id  INT UNSIGNED NOT NULL,
  order_date   DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  total_amount DECIMAL(12, 2) NOT NULL,
  PRIMARY KEY (order_id),
  CONSTRAINT fk_orders_customer
    FOREIGN KEY (customer_id) REFERENCES Customers (customer_id)
    ON DELETE CASCADE
    ON UPDATE CASCADE
) ENGINE=InnoDB;

CREATE TABLE Order_Items (
  order_item_id INT UNSIGNED NOT NULL AUTO_INCREMENT,
  order_id      INT UNSIGNED NOT NULL,
  mobile_id     INT UNSIGNED NOT NULL,
  quantity      INT UNSIGNED NOT NULL,
  PRIMARY KEY (order_item_id),
  CONSTRAINT fk_order_items_order
    FOREIGN KEY (order_id) REFERENCES Orders (order_id)
    ON DELETE CASCADE
    ON UPDATE CASCADE,
  CONSTRAINT fk_order_items_mobile
    FOREIGN KEY (mobile_id) REFERENCES Mobiles (mobile_id)
    ON DELETE RESTRICT
    ON UPDATE CASCADE,
  CONSTRAINT chk_order_items_qty_positive CHECK (quantity > 0)
) ENGINE=InnoDB;

CREATE TABLE Payments (
  payment_id      INT UNSIGNED NOT NULL AUTO_INCREMENT,
  order_id        INT UNSIGNED NOT NULL,
  payment_method  VARCHAR(40) NOT NULL,
  payment_status  VARCHAR(30) NOT NULL,
  PRIMARY KEY (payment_id),
  UNIQUE KEY uq_payments_order (order_id),
  CONSTRAINT fk_payments_order
    FOREIGN KEY (order_id) REFERENCES Orders (order_id)
    ON DELETE CASCADE
    ON UPDATE CASCADE
) ENGINE=InnoDB;

-- -----------------------------------------------------------------------------
-- 3. Sample data (at least 5 rows per table)
-- -----------------------------------------------------------------------------

INSERT INTO Customers (name, email, phone, address) VALUES
  ('Ananya Sharma', 'ananya.sharma@gmail.com', '+91-9876504321', '12 MG Road, Bengaluru, Karnataka'),
  ('Rahul Verma', 'rahul.verma@outlook.com', '+91-9123456780', '45 Park Street, Kolkata, West Bengal'),
  ('Priya Nair', 'priya.nair@yahoo.com', '+91-9988776655', '78 Marine Drive, Kochi, Kerala'),
  ('Vikram Singh', 'vikram.singh@proton.me', '+91-9811122233', 'Plot 9, Sector 22, Noida, Uttar Pradesh'),
  ('Meera Iyer', 'meera.iyer@live.com', '+91-9345612789', '22 Anna Salai, Chennai, Tamil Nadu'),
  ('Arjun Patel', 'arjun.patel@gmail.com', '+91-9001122334', '5 Ring Road, Ahmedabad, Gujarat');

INSERT INTO Mobiles (brand, model, price, stock) VALUES
  ('Samsung', 'Galaxy S24 Ultra', 124999.00, 40),
  ('Apple', 'iPhone 15 Pro', 134900.00, 25),
  ('Google', 'Pixel 8 Pro', 89999.00, 30),
  ('OnePlus', '12', 64999.00, 55),
  ('Xiaomi', '14 Ultra', 99999.00, 20),
  ('Nothing', 'Phone (2)', 44999.00, 60);

INSERT INTO Orders (customer_id, order_date, total_amount) VALUES
  (1, '2026-03-02 10:15:00', 124999.00),
  (2, '2026-03-05 14:40:00', 134900.00),
  (3, '2026-03-08 09:05:00', 179998.00),
  (4, '2026-03-10 16:22:00', 64999.00),
  (5, '2026-03-12 11:30:00', 89999.00),
  (6, '2026-03-15 13:45:00', 44999.00);

INSERT INTO Order_Items (order_id, mobile_id, quantity) VALUES
  (1, 1, 1),
  (2, 2, 1),
  (3, 3, 2),
  (4, 4, 1),
  (5, 3, 1),
  (6, 6, 1),
  (2, 6, 1);

UPDATE Orders o
SET total_amount = (
  SELECT COALESCE(SUM(oi.quantity * m.price), 0)
  FROM Order_Items oi
  JOIN Mobiles m ON m.mobile_id = oi.mobile_id
  WHERE oi.order_id = o.order_id
);

INSERT INTO Payments (order_id, payment_method, payment_status) VALUES
  (1, 'UPI', 'Completed'),
  (2, 'Credit Card', 'Completed'),
  (3, 'Net Banking', 'Completed'),
  (4, 'Debit Card', 'Completed'),
  (5, 'UPI', 'Completed'),
  (6, 'Wallet', 'Completed');

-- -----------------------------------------------------------------------------
-- 4. Views (at least 2)
-- -----------------------------------------------------------------------------

CREATE OR REPLACE VIEW customer_orders AS
SELECT
  c.customer_id,
  c.name AS customer_name,
  c.email,
  o.order_id,
  o.order_date,
  o.total_amount
FROM Customers c
INNER JOIN Orders o ON o.customer_id = c.customer_id;

CREATE OR REPLACE VIEW sales_summary AS
SELECT
  m.brand,
  m.model,
  SUM(oi.quantity) AS units_sold,
  SUM(oi.quantity * m.price) AS revenue,
  AVG(m.price) AS avg_unit_price
FROM Order_Items oi
INNER JOIN Mobiles m ON m.mobile_id = oi.mobile_id
GROUP BY m.mobile_id, m.brand, m.model;

-- -----------------------------------------------------------------------------
-- 5. Example queries (SELECT, INNER JOIN, aggregates, subqueries)
-- -----------------------------------------------------------------------------

-- SELECT: all customers
SELECT customer_id, name, email, phone
FROM Customers
ORDER BY name;

-- SELECT: mobiles in stock
SELECT brand, model, price, stock
FROM Mobiles
WHERE stock > 0
ORDER BY price DESC;

-- INNER JOIN: orders with customer names
SELECT
  o.order_id,
  c.name AS customer_name,
  o.order_date,
  o.total_amount
FROM Orders o
INNER JOIN Customers c ON c.customer_id = o.customer_id
ORDER BY o.order_date DESC;

-- INNER JOIN: order line details
SELECT
  o.order_id,
  c.name AS customer_name,
  m.brand,
  m.model,
  oi.quantity,
  (oi.quantity * m.price) AS line_total
FROM Orders o
INNER JOIN Customers c ON c.customer_id = o.customer_id
INNER JOIN Order_Items oi ON oi.order_id = o.order_id
INNER JOIN Mobiles m ON m.mobile_id = oi.mobile_id
ORDER BY o.order_id, oi.order_item_id;

-- Aggregate: total revenue from completed payments
SELECT SUM(o.total_amount) AS total_revenue
FROM Orders o
INNER JOIN Payments p ON p.order_id = o.order_id
WHERE p.payment_status = 'Completed';

-- Aggregate: order count per customer
SELECT
  c.customer_id,
  c.name,
  COUNT(o.order_id) AS order_count
FROM Customers c
LEFT JOIN Orders o ON o.customer_id = c.customer_id
GROUP BY c.customer_id, c.name
ORDER BY order_count DESC;

-- Aggregate: average mobile price by brand
SELECT
  brand,
  AVG(price) AS avg_price,
  COUNT(*) AS model_count
FROM Mobiles
GROUP BY brand
ORDER BY avg_price DESC;

-- Subquery: customers who spent above overall average order value
SELECT c.name, o.total_amount
FROM Orders o
INNER JOIN Customers c ON c.customer_id = o.customer_id
WHERE o.total_amount > (
  SELECT AVG(total_amount) FROM Orders
);

-- Subquery: mobiles priced higher than brand average (Samsung example)
SELECT m.model, m.price
FROM Mobiles m
WHERE m.brand = 'Samsung'
  AND m.price > (
    SELECT AVG(m2.price) FROM Mobiles m2 WHERE m2.brand = 'Samsung'
  );

-- Subquery IN: orders that include Google Pixel models
SELECT DISTINCT o.order_id, o.order_date, o.total_amount
FROM Orders o
WHERE o.order_id IN (
  SELECT oi.order_id
  FROM Order_Items oi
  INNER JOIN Mobiles m ON m.mobile_id = oi.mobile_id
  WHERE m.brand = 'Google'
);

-- Views in use
SELECT * FROM customer_orders ORDER BY order_date DESC;
SELECT * FROM sales_summary ORDER BY revenue DESC;
