-- ========================================================
-- 1. NORMALIZED RELATIONAL SCHEMA (3NF)
-- ========================================================

CREATE TABLE Customers (
    customer_id INT PRIMARY KEY,
    customer_name VARCHAR(100),
    segment VARCHAR(50),
    region VARCHAR(50)
);

CREATE TABLE Orders (
    order_id INT PRIMARY KEY,
    customer_id INT,
    order_date DATE,
    FOREIGN KEY (customer_id) REFERENCES Customers(customer_id)
);

CREATE TABLE Order_Items (
    item_id INT PRIMARY KEY,
    order_id INT,
    sales_amount DECIMAL(10, 2),
    profit_amount DECIMAL(10, 2),
    FOREIGN KEY (order_id) REFERENCES Orders(order_id)
);

-- ========================================================
-- 2. MONTH-OVER-MONTH REVENUE GROWTH (CTEs & WINDOW FUNCTIONS)
-- ========================================================

WITH MonthlyTotals AS (
    SELECT 
        DATE_TRUNC('month', o.order_date) AS sales_month,
        SUM(oi.sales_amount) AS revenue
    FROM Orders o
    JOIN Order_Items oi ON o.order_id = oi.order_id
    GROUP BY 1
)
SELECT 
    sales_month,
    revenue,
    LAG(revenue) OVER (ORDER BY sales_month) AS prev_month_revenue,
    ROUND(
        ((revenue - LAG(revenue) OVER (ORDER BY sales_month)) / 
        NULLIF(LAG(revenue) OVER (ORDER BY sales_month), 0)) * 100, 2
    ) AS mom_growth_pct
FROM MonthlyTotals;

-- ========================================================
-- 3. CUSTOMER RFM & LIFETIME VALUE RANKING
-- ========================================================

SELECT 
    c.customer_id,
    c.customer_name,
    c.segment,
    MAX(o.order_date) AS last_order_date,
    COUNT(DISTINCT o.order_id) AS total_orders,
    ROUND(SUM(oi.sales_amount), 2) AS total_spend,
    DENSE_RANK() OVER (ORDER BY SUM(oi.sales_amount) DESC) AS customer_rank
FROM Customers c
JOIN Orders o ON c.customer_id = o.customer_id
JOIN Order_Items oi ON o.order_id = oi.order_id
GROUP BY c.customer_id, c.customer_name, c.segment
ORDER BY customer_rank ASC
LIMIT 10;
