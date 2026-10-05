-- ---------------------------------------
-- Q1. How much revenue did the business generate in total,
--     and how much of it was actually kept after
--     returns and cancellations?
-- ---------------------------------------

SELECT
    ROUND(SUM(revenue), 2) AS gross_revenue,
    ROUND(SUM(CASE WHEN order_status = 'Delivered' THEN revenue ELSE 0 END), 2) AS kept_revenue,
    ROUND(SUM(CASE WHEN order_status <> 'Delivered' THEN revenue ELSE 0 END), 2) AS lost_revenue
FROM sales_final;


-- Finding: Over 2022-2025 the business booked $2,525,316.35 gross and retained
-- $2,141,912.70 after returns and cancellations. The $383,403.65 lost equals
-- 15.18% of gross revenue, so roughly one pound in every seven booked as a
-- sale is subsequently reversed. That is a material gap: any forecast built on
-- gross revenue would overstate realised income by about 15%, making kept
-- revenue the correct basis for planning.

-- ---------------------------------------
-- Q2. Which regions carry the business, and does any
--     region lose a disproportionate share of its
--     revenue to returns and cancellations?
-- ---------------------------------------

WITH region_wise AS (SELECT
	region,
    COUNT(*) AS order_count,
    ROUND(SUM(revenue), 2) AS gross_revenue,
    ROUND(SUM(CASE WHEN order_status = 'Delivered' THEN revenue ELSE 0 END), 2) AS kept_revenue,
    ROUND(SUM(CASE WHEN order_status <> 'Delivered' THEN revenue ELSE 0 END), 2) AS lost_revenue
FROM sales_final
GROUP BY region)
SELECT *,
ROUND((lost_revenue/gross_revenue)*100,2) AS lost_pct
FROM region_wise
ORDER BY kept_revenue;

-- Finding: Revenue is heavily concentrated in East, which generates
-- $806,876.07 kept revenue from 7,248 orders, more than double North's
-- $387,337.64 from 3,245 orders. East alone accounts for 37.7% of total kept
-- revenue. Average order value is similar across regions ($119 to $131), so
-- the gap is driven by order volume rather than basket size: East places
-- 2.2x as many orders as North. Loss rates cluster between 13.82% and 16.44%,
-- with North lowest and West highest, a spread too narrow to indicate a
-- genuine operational difference.

-- ---------------------------------------
-- Q3. Which product categories generate the most revenue,
--     and are the high earners also the ones most likely
--     to be returned?
-- ---------------------------------------

WITH category_wise AS(SELECT
	category,
    COUNT(*) AS order_count,
    COUNT(CASE WHEN order_status = 'Delivered' THEN 1 END) AS kept_count,
    COUNT(CASE WHEN order_status <> 'Delivered' THEN 1 END) AS return_count,
    ROUND(SUM(revenue), 2) AS gross_revenue,
    ROUND(SUM(CASE WHEN order_status = 'Delivered' THEN revenue ELSE 0 END), 2) AS kept_revenue,
    ROUND(SUM(CASE WHEN order_status <> 'Delivered' THEN revenue ELSE 0 END), 2) AS lost_revenue
FROM sales_final
GROUP BY category)
SELECT
	*,
    ROUND((return_count/order_count)*100,2) AS return_pct
FROM category_wise
ORDER BY kept_revenue DESC;


-- Finding: Volume and value run in opposite directions. Grocery has the most
-- orders (4,663) but the least revenue ($198,207.73), while Furniture has the
-- fewest orders (2,595) and the most revenue ($687,926.80), 3.5x Grocery's
-- from 44% fewer orders. Furniture and Electronics together hold 58% of kept
-- revenue from just 32% of orders.
--
-- Return rates vary sharply and are the widest spread in the dataset:
-- Electronics 20.16% against Grocery 7.42%, a factor of 2.7. Electronics is
-- the only category where losses ($141,155.68) exceed Furniture's despite
-- lower gross revenue, so it carries both the highest return rate and the
-- largest absolute loss.


-- ---------------------------------------
-- Q4. How does revenue split across customer segments,
--     and do Retail, Wholesale and Online customers
--     differ in how much of their revenue sticks?
-- ---------------------------------------

WITH platform AS (SELECT
	customer_segment,
    COUNT(*) AS order_count,
    COUNT(CASE WHEN order_status = 'Delivered' THEN 1 END) AS kept_count,
    COUNT(CASE WHEN order_status <> 'Delivered' THEN 1 END) AS return_count,
    ROUND(SUM(revenue), 2) AS gross_revenue,
    ROUND(SUM(CASE WHEN order_status = 'Delivered' THEN revenue ELSE 0 END), 2) AS kept_revenue,
    ROUND(SUM(CASE WHEN order_status <> 'Delivered' THEN revenue ELSE 0 END), 2) AS lost_revenue
FROM sales_final
GROUP BY customer_segment)
SELECT 
	*,
    ROUND((return_count/order_count)*100,2) AS return_pct,
    ROUND((lost_revenue/gross_revenue)*100,2) AS lost_pct
FROM platform
ORDER BY kept_revenue DESC;


-- Finding: Wholesale is the dominant segment by revenue despite being the
-- smallest by volume. It places 4,022 orders (21% of the total) yet generates
-- $1,054,134.42 kept revenue, 49% of the business and more than Retail and
-- Online combined. Average order value explains it: roughly $297 for
-- Wholesale against $79 for Retail and $82 for Online, a 3.7x gap.
--
-- Return rates are near-identical across segments (11.86% to 12.75%), and
-- revenue-based loss rates sit consistently 2 to 3 points above count-based
-- rates in every segment, meaning returned orders skew more expensive than
-- kept ones regardless of who places them.


-- ---------------------------------------
-- Q5. Which individual products drive the most revenue,
--     and which sit at the bottom of the range?
-- ---------------------------------------


WITH product AS (
    SELECT
        product_name,
        COUNT(*) AS order_count,
        COUNT(CASE WHEN order_status <> 'Delivered' THEN 1 END) AS return_count,
        ROUND(SUM(revenue), 2) AS total_rev
    FROM sales_final
    GROUP BY product_name
)
(SELECT
    *,
    ROUND((return_count / order_count) * 100, 2) AS return_pct,
    'Best' AS rank_type
 FROM product
 ORDER BY total_rev DESC
 LIMIT 1)
UNION ALL
(SELECT
    *,
    ROUND((return_count / order_count) * 100, 2),
    'Worst'
 FROM product
 ORDER BY total_rev ASC
 LIMIT 1);


-- Finding: Headphones is the highest-earning product at $235,279.16 from 758
-- orders, while Pasta Pack earns the least at $28,128.13 despite having 1,371
-- orders, nearly twice as many. Revenue per order is $310 against $21, a 15x
-- gap. Notably Headphones is not the most expensive product in the catalogue,
-- so the revenue ranking reflects a combination of price and demand rather
-- than price alone. Their return rates also diverge sharply, 21.37% against
-- 7.59%, consistent with the category pattern where Electronics returns far
-- more often than Grocery.