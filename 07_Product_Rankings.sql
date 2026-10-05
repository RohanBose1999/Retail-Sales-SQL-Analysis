-- ---------------------------------------
-- Q1. Which three products generate the most revenue within
--     each category, and how much of each category's revenue
--     do its top three account for?
-- ---------------------------------------

WITH top AS (SELECT
	category,
    product_name,
    ROUND(SUM(CASE WHEN order_status =  'Delivered' THEN revenue ELSE 0 END),2) AS total_revenue
FROM sales_final
GROUP BY product_name, category),
ranked AS(SELECT *,
RANK() OVER(PARTITION BY category ORDER BY total_revenue DESC) AS rnk,
SUM(total_revenue) OVER (PARTITION BY category) AS category_total,
ROUND(total_revenue / (SUM(total_revenue) OVER (PARTITION BY category)) * 100, 2) AS pct_of_category
FROM top)
SELECT *
FROM ranked
WHERE rnk < 4
ORDER BY category, rnk;

-- Finding: Top-three concentration runs 65% to 76% of category revenue, with
-- Furniture flattest (Bookshelf 23.88%, Office Chair 23.15%) and Electronics
-- most top-heavy (Headphones 33.13%). The ranking is not the price list:
-- Study Desk, the most expensive item in the catalogue, does not place in
-- Furniture's top three at all, selling 207 times against Bookshelf's 475.
-- Revenue leadership reflects the balance of price and demand, not price alone.

-- ---------------------------------------
-- Q2. Which single month was strongest for each region, and
--     do the regions peak at the same time or at different
--     points in the year?
-- ---------------------------------------

WITH monthly AS (SELECT
DATE_FORMAT(order_date, '%Y-%m') as order_month,
region,
ROUND(SUM(CASE WHEN order_status =  'Delivered' THEN revenue ELSE 0 END),2) AS monthly_revenue
FROM sales_final
GROUP BY order_month, region),
ranked AS (SELECT *,
ROW_NUMBER() OVER(PARTITION BY region ORDER BY monthly_revenue DESC) AS rnk
FROM monthly)
SELECT *
FROM ranked
WHERE rnk = 1;

-- Finding: Three of four regions peak in December (East Dec 2022 at
-- $35,207.23, North Dec 2024, West Dec 2025), consistent with the seasonal
-- pattern in script 04. South is the exception, peaking in January 2025 at
-- $20,281.32. East's peak is more than double North's despite both falling in
-- December, reflecting the regional size gap rather than any timing
-- difference. The peaks also fall in different years, which reflects noise at
-- this grain rather than a trend.

-- ---------------------------------------
-- Q3. Which products sell above and below the overall average
--     price, and does sitting on either side of that line
--     relate to how much revenue they generate?
-- ---------------------------------------

WITH product_prices AS (SELECT
    product_name,
    category,
    ROUND(AVG(price), 2) AS avg_price,
    ROUND(SUM(CASE WHEN order_status = 'Delivered' THEN revenue ELSE 0 END), 2) AS total_revenue
FROM sales_final
GROUP BY product_name, category)
SELECT
    product_name,
    category,
    avg_price,
    ROUND(AVG(avg_price) OVER (), 2) AS overall_avg_price,
    CASE
        WHEN avg_price >= AVG(avg_price) OVER () THEN 'Above average'
        ELSE 'Below average'
    END AS price_position,
    total_revenue
FROM product_prices
ORDER BY avg_price DESC;

-- Finding: Nine of 25 products sit above the overall average price of $51.10,
-- but price position is a poor guide to revenue. Study Desk, the most
-- expensive product at $189.63, earns $125,453.21, less than Bookshelf
-- ($100.44) at $164,305.72 and only marginally ahead of Desk Lamp ($36.95)
-- at $112,864.70 despite costing five times as much. Several below-average
-- products out-earn above-average ones: Jeans ($119,349.63) beats Jacket
-- ($102,648.21), and Desk Lamp beats Bluetooth Speaker ($102,483.95).
-- Revenue is set by price and demand together, so the price line separates
-- the catalogue without explaining it.