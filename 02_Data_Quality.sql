#Checking null value count
SELECT
    SUM(order_id IS NULL)         AS null_order_id,
    SUM(order_date IS NULL)       AS null_order_date,
    SUM(customer_id IS NULL)      AS null_customer_id,
    SUM(customer_segment IS NULL) AS null_customer_segment,
    SUM(region IS NULL)           AS null_region,
    SUM(category IS NULL)         AS null_category,
    SUM(product_name IS NULL)     AS null_product_name,
    SUM(price IS NULL)            AS null_price,
    SUM(units IS NULL)            AS null_units,
    SUM(discount_pct IS NULL)     AS null_discount_pct,
    SUM(payment_method IS NULL)   AS null_payment_method,
    SUM(order_status IS NULL)     AS null_order_status
FROM sales;
-- Finding: Of the 19,542 rows loaded, missing values appear in only two
-- columns: price (781 rows, 4.0%) and units (683 rows, 3.5%). All identifier,
-- date, and categorical fields are complete, so cleaning can focus on
-- numeric imputation alone.
# FROM HERE WE CAN CLEARLY SEE THAT PRICE AND UNITS ARE EMPTY SO WE WILL BE CHANGING THE VALUES BY MEAN/AVG

# Findnig MEAN according to category
SELECT
category,
ROUND(AVG(price),2) avg_price,
ROUND(AVG(units),0) avg_units
FROM sales
GROUP BY category;

# Findnig MEAN according to category after null data imputation to check if there is a big difference
WITH ech AS (SELECT
    s.order_id,
    s.order_date,
    s.customer_id,
    s.customer_segment,
    s.region,
    s.category,
    s.product_name,
    ROUND(COALESCE(s.price, p.avg_price), 2) AS price,
    ROUND(COALESCE(s.units, p.avg_units), 0)    AS units,
    s.discount_pct,
    s.payment_method,
    s.order_status
FROM sales s
JOIN(
SELECT
product_name,
ROUND(AVG(price),2) avg_price,
ROUND(AVG(units),0) avg_units
FROM sales
GROUP BY product_name) p
ON s.product_name = p.product_name)
SELECT 
category,
ROUND(AVG(price),2) avg_price,
ROUND(AVG(units),0) avg_units
FROM ech
GROUP BY category;
-- Finding: Per-product mean imputation leaves category-level averages
-- essentially unchanged. The largest shift in average price is Furniture
-- ($79.73 to $79.93, 0.25%), and average units are identical across all five
-- categories. Filling 781 prices and 683 units therefore introduces no
-- meaningful distortion, confirming the imputation is safe to carry forward.

# since there is no significant difference we can now create the new table with the cleaned data
CREATE TABLE sales_cleaned AS
SELECT
    s.order_id,
    s.order_date,
    s.customer_id,
    s.customer_segment,
    s.region,
    s.category,
    s.product_name,
    ROUND(COALESCE(s.price, p.avg_price), 2) AS price,
    ROUND(COALESCE(s.units, p.avg_units))    AS units,
    s.discount_pct,
    s.payment_method,
    TRIM(REPLACE(s.order_status, '\r', '')) AS order_status
FROM sales s
JOIN (
    SELECT product_name,
           AVG(price) AS avg_price,
           AVG(units) AS avg_units
    FROM sales
    GROUP BY product_name
) p ON s.product_name = p.product_name;


#Running null check again
SELECT
    SUM(order_id IS NULL)         AS null_order_id,
    SUM(order_date IS NULL)       AS null_order_date,
    SUM(customer_id IS NULL)      AS null_customer_id,
    SUM(customer_segment IS NULL) AS null_customer_segment,
    SUM(region IS NULL)           AS null_region,
    SUM(category IS NULL)         AS null_category,
    SUM(product_name IS NULL)     AS null_product_name,
    SUM(price IS NULL)            AS null_price,
    SUM(units IS NULL)            AS null_units,
    SUM(discount_pct IS NULL)     AS null_discount_pct,
    SUM(payment_method IS NULL)   AS null_payment_method,
    SUM(order_status IS NULL)     AS null_order_status
FROM sales_cleaned;
# now we can see that there are no null values

-- Verifying order_status is clean (was showing a duplicate 'Delivered' due to stray \r)
SELECT order_status, LENGTH(order_status) AS len, COUNT(*) AS n
FROM sales_cleaned
GROUP BY order_status;
-- expect exactly 3 rows: Delivered(9), Returned(8), Cancelled(9)

# FINDING revenue
SELECT *,
ROUND(((price*units)*(1-(discount_pct/100))),2) AS revenue
FROM sales_cleaned;

#Now creating the final dataset with revenue
CREATE TABLE sales_final AS
SELECT
    order_id,
    order_date,
    customer_id,
    customer_segment,
    region,
    category,
    product_name,
    price,
    units,
    discount_pct,
    payment_method,
    order_status,
    ROUND(((price * units) * (1 - (discount_pct / 100))), 2) AS revenue
FROM sales_cleaned;

#Selecting all rows for export purpose
SELECT * FROM sales_final;