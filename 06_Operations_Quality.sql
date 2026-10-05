-- ---------------------------------------
-- Q1. How much revenue is given away through discounting,
--     and how is that cost distributed across the discount
--     bands actually in use?
-- ---------------------------------------

SELECT
    CASE
        WHEN discount_pct = 0 THEN 'No Discount'
        WHEN discount_pct < 11 THEN 'Between 1%-10%'
        ELSE 'Between 11%-20%'
    END AS discount_band,
    COUNT(*) AS order_count,
    ROUND(SUM(price * units), 2) AS pre_discount_value,
    ROUND(SUM(revenue), 2) AS revenue_after_discount,
    ROUND(SUM(price * units) - SUM(revenue), 2) AS discount_given
FROM sales_final
GROUP BY discount_band
ORDER BY discount_given DESC;

-- Finding: Discounting cost $173,981.60 across the period, 6.4% of the $2.70M
-- pre-discount value. Most orders carry no discount at all (10,949 of 19,542,
-- or 56%). Cost is driven by depth rather than breadth: the 2,952 orders in
-- the 11-20% band give away $111,918.70, nearly twice the $62,062.90 from the
-- 5,641 orders discounted 1-10%, despite being roughly half as many. Average
-- discount per order is $37.91 in the deep band against $11.00 in the shallow
-- one.


-- ---------------------------------------
-- Q2. Which categories and products lose the most money to
--     returns and cancellations in absolute terms, and does
--     that ranking differ from the loss-rate ranking?
-- ---------------------------------------

-- BY CATEGORIES

SELECT
	category,
    COUNT(*) AS order_count,
    ROUND(SUM(CASE WHEN order_status <> 'Delivered' THEN revenue ELSE 0 END), 2) AS lost_revenue,
    ROUND(SUM(CASE WHEN order_status <> 'Delivered' THEN revenue ELSE 0 END)
          / SUM(revenue) * 100, 2) AS lost_pct
FROM sales_final
GROUP BY category
ORDER BY lost_revenue DESC;

-- Finding: Electronics leads on both measures, losing $141,155.68 at a 20.22%
-- rate, well clear of Furniture ($122,672.63 at 15.13%) despite placing 43%
-- more orders at lower prices. Beauty and Grocery sit far below on both counts,
-- together losing $36,997.25 at rates around 7-8%, roughly a third of
-- Electronics' rate. Loss is therefore concentrated in a category that is both
-- high-value and high-return, making Electronics the clear target for any
-- returns-reduction effort.

-- BY PRODUCT
SELECT
	category,
	product_name,
    COUNT(*) AS order_count,
    ROUND(SUM(CASE WHEN order_status <> 'Delivered' THEN revenue ELSE 0 END), 2) AS lost_revenue,
    ROUND(SUM(CASE WHEN order_status <> 'Delivered' THEN revenue ELSE 0 END)
          / SUM(revenue) * 100, 2) AS lost_pct
FROM sales_final
GROUP BY category, product_name
ORDER BY lost_revenue DESC;

-- Finding: Losses reflect price, volume and return rate combined. Headphones
-- tops the list at $50,731.06, double Smartwatch's $35,870.40 despite being
-- the cheaper product, because it sells 2.4x as often. Return rates split by
-- category rather than price: all five Electronics products sit between 16.75%
-- and 21.56%, all five Grocery products between 6.49% and 8.29%, so the driver
-- is what the product is rather than what it costs.


-- ---------------------------------------
-- Q3. How is the payment method mix distributed, and has it
--     shifted across the four-year period?
-- ---------------------------------------

SELECT
	YEAR(order_date) AS order_year,
    payment_method,
    COUNT(*) AS payment_count,
    ROUND(COUNT(*) / SUM(COUNT(*)) OVER (PARTITION BY YEAR(order_date)) * 100, 2) AS pct_of_year
FROM sales_final
GROUP BY payment_method, order_year
ORDER BY payment_method, order_year;


-- Finding: The payment mix has shifted substantially. Cash fell from 25.63%
-- of orders in 2022 to 7.92% in 2025, losing roughly two thirds of its share,
-- while UPI rose from 14.27% to 35.45% over the same period. The two cross
-- over during 2023. Card declined more gently from 44.79% to 39.86% and
-- Wallet held steady around 15-17%, so the shift is specifically a migration
-- from cash to UPI rather than a broad realignment.