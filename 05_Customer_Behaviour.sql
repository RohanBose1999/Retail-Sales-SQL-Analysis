-- ---------------------------------------
-- Q1. Which customers generate the most revenue, and how
--     concentrated is the customer base -- does a small
--     share of buyers drive a disproportionate share of
--     the money?
-- ---------------------------------------

WITH cust AS (SELECT
	customer_id,
    COUNT(*) AS order_count,
    ROUND(SUM(revenue), 2) AS gross_revenue,
    ROUND(SUM(CASE WHEN order_status = 'Delivered' THEN revenue ELSE 0 END), 2) AS kept_revenue,
    ROUND(SUM(CASE WHEN order_status <> 'Delivered' THEN revenue ELSE 0 END), 2) AS lost_revenue,
    ROUND(AVG(revenue), 2) AS avg_order_value
FROM sales_final
GROUP BY customer_id)
SELECT
	customer_id,
    ROW_NUMBER() OVER(ORDER BY kept_revenue DESC) AS customer_rank,
    order_count,
    avg_order_value,
    kept_revenue,
    ROUND(SUM(kept_revenue) OVER (ORDER BY kept_revenue DESC)
      / SUM(kept_revenue) OVER () * 100, 2) AS cumulative_pct
FROM cust
ORDER BY kept_revenue DESC;


-- Finding: Revenue is heavily concentrated. The top 10% of customers hold
-- 47.90% of kept revenue, the top 20% hold 66.22%, and the top half account
-- for 90.68%, close to a classic Pareto distribution. CUST0165 alone
-- contributes 2.89% ($61,838.75), and the top ten customers together hold
-- 15.41%.
--
-- Two routes reach the top: volume and basket size. CUST0073 ranks 17th on
-- 140 orders at an average of $115.30, while CUST0765 ranks 6th on just 37
-- orders at $745.89. At the other end, six customers have zero kept revenue
-- because every order they placed was returned or cancelled, including
-- CUST0554 whose single $1,394.71 order was reversed in full.


-- ---------------------------------------
-- Q2. Do customers concentrate their spending in a single
--     product category, or spread it across many -- and
--     does breadth of purchasing relate to how much they
--     spend overall?
-- ---------------------------------------

WITH cust AS (SELECT
    customer_id,
    COUNT(DISTINCT category) AS categories_bought,
    COUNT(*) AS order_count,
    ROUND(SUM(CASE WHEN order_status = 'Delivered' THEN revenue ELSE 0 END), 2) AS kept_revenue
FROM sales_final
GROUP BY customer_id)
SELECT 
	categories_bought,
    COUNT(*) AS customer_count,
    ROUND(AVG(kept_revenue), 2) AS avg_kept_revenue
FROM cust
GROUP BY categories_bought
ORDER BY categories_bought;

-- Finding: Purchasing breadth varies genuinely across the base. 99 customers
-- buy from a single category and 261 from all five, with the rest spread
-- between. Breadth relates strongly to value at the extremes: single-category
-- customers average $375.18 kept revenue against $4,240.35 for five-category
-- customers, an 11x gap. The middle is flat, however, with two, three and
-- four category buyers all averaging between $2,057 and $2,517, so breadth
-- only separates customers at the ends of the range.


-- ---------------------------------------
-- Q3. How long do customers stay active between their
--     first and last order, and does a longer lifespan
--     translate into more orders?
-- ---------------------------------------

WITH cust AS (
    SELECT customer_id,
           DATEDIFF(MAX(order_date), MIN(order_date)) AS lifespan_days
    FROM sales_final
    GROUP BY customer_id
)
SELECT MIN(lifespan_days), MAX(lifespan_days), ROUND(AVG(lifespan_days)) 
FROM cust;

-- Finding: Lifespans now range from 0 to 1,445 days against a possible 1,461,
-- averaging 713. The zero minimum reflects genuine one-time buyers whose first
-- and last order are the same day, and the average sitting at less than half
-- the full window shows substantial churn: most customers are active for only
-- part of the period rather than throughout.


WITH cust AS (SELECT
        customer_id,
        DATEDIFF(MAX(order_date), MIN(order_date)) AS lifespan_days,
        COUNT(*) AS order_count
FROM sales_final
GROUP BY customer_id)
SELECT
CASE
	WHEN lifespan_days < 1300 THEN 'Under 1300 days'
	WHEN lifespan_days < 1400 THEN '1300-1399 days'
	ELSE '1400+ days'
END AS lifespan_band,
COUNT(*) AS customer_count,
ROUND(AVG(order_count),2) AS avg_order,
SUM(order_count) AS all_orders
FROM cust
GROUP BY lifespan_band
ORDER BY customer_count DESC;

-- Finding: Order count rises sharply with lifespan. Customers active under
-- 1,300 days average 20.55 orders, those at 1,300-1,399 average 40.16, and the
-- 14 customers surviving 1,400+ days average 72.71, more than triple the
-- shortest band. The distribution is heavily skewed toward short lifespans:
-- 665 of 800 customers fall in the lowest band and contribute 70% of all
-- orders, while the longest-lived 14 contribute only 5%.