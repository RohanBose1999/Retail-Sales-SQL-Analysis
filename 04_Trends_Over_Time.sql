-- ---------------------------------------
-- Q1. How does revenue break down month by month, and is
--     the share lost to returns and cancellations stable
--     or worsening over time?
-- ---------------------------------------

WITH monthly_change AS (SELECT
    DATE_FORMAT(order_date, '%Y-%m') AS order_month,
    ROUND(SUM(revenue), 2) AS gross_revenue,
    ROUND(SUM(CASE WHEN order_status = 'Delivered' THEN revenue ELSE 0 END), 2) AS kept_revenue,
    ROUND(SUM(CASE WHEN order_status <> 'Delivered' THEN revenue ELSE 0 END), 2) AS lost_revenue,
    ROUND(SUM(CASE WHEN order_status <> 'Delivered' THEN revenue ELSE 0 END)
      / SUM(revenue) * 100, 2) AS lost_pct
FROM sales_final
GROUP BY DATE_FORMAT(order_date, '%Y-%m')),
last_rev AS (SELECT
	*,
    LAG(kept_revenue) OVER(ORDER BY order_month) AS last_revenue
FROM monthly_change)
SELECT
	*,
    ROUND(((kept_revenue - last_revenue)/last_revenue)*100,2) AS pct_change
FROM last_rev
ORDER BY order_month;

-- Finding: A clear slump runs from April to August 2023, with kept revenue
-- dropping to $22,826.68 in April against $35,901.15 in March and staying
-- below $33k for five months before recovering from September. December peaks
-- in every year without exception. Month-over-month growth swings from -40.21%
-- to +82.85%, driven by seasonality and the 2022 ramp-up rather than
-- performance, so it is not a reliable measure here.

-- ---------------------------------------
-- Q2. Is the business growing year on year, and does the
--     rate of revenue loss change as it grows?
-- ---------------------------------------

WITH yearly_change AS (SELECT
    YEAR(order_date) AS order_year,
    ROUND(SUM(revenue), 2) AS gross_revenue,
    ROUND(SUM(CASE WHEN order_status = 'Delivered' THEN revenue ELSE 0 END), 2) AS kept_revenue,
    ROUND(SUM(CASE WHEN order_status <> 'Delivered' THEN revenue ELSE 0 END), 2) AS lost_revenue,
    ROUND(SUM(CASE WHEN order_status <> 'Delivered' THEN revenue ELSE 0 END)
      / SUM(revenue) * 100, 2) AS lost_pct
FROM sales_final
GROUP BY YEAR(order_date)),
previous_year AS (
SELECT
	order_year,
	gross_revenue,
    kept_revenue,
    lost_revenue,
    lost_pct,
    LAG(kept_revenue) OVER(ORDER BY order_year) AS last_revenue
FROM yearly_change)
SELECT
	order_year,
	gross_revenue,
    kept_revenue,
    lost_revenue,
    lost_pct,
    ROUND(((kept_revenue - last_revenue)/last_revenue)*100,2) AS pct_change
FROM previous_year
ORDER BY order_year;


-- Finding: Revenue fell 16.66% in 2023 to $434,525.03, the only contraction
-- in the period, driven by the April to August slump. Recovery was strong:
-- +20.14% in 2024 and +27.18% in 2025, ending at $663,928.63, 27% above the
-- 2022 base. Loss rates stay within a narrow 13.97% to 16.75% band throughout,
-- so the 2023 downturn was a volume problem rather than a quality one.


-- ---------------------------------------
-- Q3. Which calendar months are consistently strongest and
--     weakest across the four-year period, and how large
--     is the seasonal swing?
-- ---------------------------------------

SELECT
	MONTH(order_date) AS month_number,
    MONTHNAME(order_date) AS month_name,
    ROUND(SUM(revenue),2) AS gross_revenue,
    ROUND(SUM(CASE WHEN order_status = 'Delivered' THEN revenue ELSE 0 END),2) AS kept_revenue
FROM sales_final
GROUP BY month_number, month_name
ORDER BY kept_revenue DESC;


-- Finding: December leads clearly at $268,286.44 kept revenue, 24% ahead of
-- November in second place, and 83% above February at the bottom. After the
-- top two the ranking flattens sharply: months three through eleven sit
-- between $157,063 and $178,672, a spread of under 14% that is too narrow to
-- read as a genuine ordering. The usable seasonal signal is therefore a
-- November and December peak against an otherwise level year, with February
-- weakest.