CREATE TABLE sales (
    order_id VARCHAR(15),
    order_date DATE,
    customer_id VARCHAR(10),
    customer_segment VARCHAR(15),
    region VARCHAR(10),
    category VARCHAR(20),
    product_name VARCHAR(30),
    price DECIMAL(8,2),
    units INT,
    discount_pct INT,
    payment_method VARCHAR(10),
    order_status VARCHAR(12)
);


LOAD DATA LOCAL INFILE '/Users/rohan/Desktop/MySQL Project/sales_data.csv'
INTO TABLE sales
FIELDS TERMINATED BY ','
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(order_id, @order_date, customer_id, customer_segment, region, category,
 product_name, @price, @units, discount_pct, payment_method, order_status)
SET order_date = STR_TO_DATE(@order_date, '%c/%e/%y'),
    price = NULLIF(@price, ''),
    units = NULLIF(@units, '');