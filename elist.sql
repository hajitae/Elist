-- 1. What is the date of the earliest and latest order, returned in one query?
-- select min and max of purchase_ts

SELECT MIN(purchase_ts),
  MAX(purchase_ts)
FROM core.orders;

-- 2. What is the average order value for purchases made in USD? What about average order value for purchases made in USD in 2019?
-- select average of usd_price, select average of usd_price where year from purchase_ts is 2019
SELECT AVG(usd_price) as aov
FROM core.orders;

SELECT AVG(usd_price) as aov_2019
FROM core.orders
WHERE EXTRACT(YEAR FROM purchase_ts) = 2019;

-- 3. Return the id, loyalty program status, and account creation date for customers who made an account on desktop or mobile. Rename the columns to more descriptive names.
-- select id, loyalty_program, created_on from customers. account_creation_method has to be desktop OR mobile. check for distinct values

SELECT id AS customer_id,
  loyalty_program AS is_loyalty_customer,
  created_on AS account_creation_date
FROM core.customers
WHERE account_creation_method = 'mobile'
  OR account_creation_method = 'desktop';

SELECT DISTINCT account_creation_method FROM core.customers;

-- 4. What are all the unique products that were sold in AUD on website, sorted alphabetically?
-- select distinct product_name from orders where currency is AUD and purchase_platform is website. order by ascending

SELECT DISTINCT product_name
FROM core.orders
WHERE currency = 'AUD' AND
  purchase_platform = 'website'
ORDER BY product_name ASC;

-- 5. What are the first 10 countries in the North American region, sorted in descending alphabetical order?
-- select country_code from geo_lookup where region is North American. order by country descending. limit to 10

SELECT country_code
FROM core.geo_lookup
WHERE region = 'NA'
ORDER BY 1 DESC
LIMIT 10;

SELECT DISTINCT region
FROM core.geo_lookup;

-- 1. What is the total number of orders by shipping month, sorted from most recent to oldest?
-- select count of ship_ts group by month order by date desc
SELECT COUNT(ship_ts) as total_orders,
  EXTRACT(MONTH FROM ship_ts) as shipping_month
FROM core.order_status
GROUP BY shipping_month;


-- 2. What is the average order value by year? Can you round the results to 2 decimals?
-- select average of usd_price then group by year
SELECT ROUND(AVG(usd_price), 2) AS aov,
EXTRACT(YEAR FROM purchase_ts) AS year
FROM core.orders
GROUP BY year;

-- 3. Create a helper column `is_refund`  in the `order_status`  table that returns 1 if there is a refund, 0 if not. Return the first 20 records.
-- select all,is_refund (case 1 if refund_ts is not null case 0 if refund_ts is null) from order_status limit 20
SELECT *,
CASE WHEN refund_ts IS NOT NULL THEN 1
  ELSE 0
END AS is_refund
FROM core.order_status
LIMIT 20;

-- 4. Return the product IDs and product names of all Apple products.
-- select product id, product name from suppliers where name is like 'Apple' or 'Macbook'
select product_name,
  product_id
FROM core.orders
WHERE product_name LIKE 'Apple%' OR
  product_name LIKE 'Macbook%';

-- 5. Calculate the time to ship in days for each order and return all original columns from the table.
-- select all, ship_ts - purchase_ts from order status
SELECT *,
  date_diff(ship_ts, purchase_ts, day) as days_to_ship
FROM core.order_status;

-- 1. What is the refund rate per year, expressed as a percent (i.e. 0.0445 should be shown as 44.5)? Can you round this to 2 decimals? 
-- select round((is_refund / total orders) * 100, 2) group by year
SELECT
  EXTRACT(YEAR FROM purchase_ts) AS year,
  ROUND(AVG(CASE WHEN refund_ts IS NOT NULL THEN 1 ELSE 0 END) * 100,2) as refund_rate
FROM core.order_status
GROUP BY year;


-- 2. What is the total number of orders per year for each product? Clean up product names when grouping and return in alphabetical order after sorting by months.
-- compile and sort a list of products
SELECT DISTINCT product_name
FROM core.orders
ORDER BY 1;

-- select month from purchase date, clean and make product names consistent
SELECT DATE_TRUNC(purchase_ts,month) AS month,
  CASE WHEN product_name = '27in"" 4k gaming onitor' THEN '27in 4k gaming monitor'
    ELSE product_name
    END AS cleaned_product_name,
  COUNT(DISTINCT id) AS order_count
FROM core.orders
GROUP BY 1, 2
ORDER BY 1, 2;

-- 3. What is the average order value per year for products that are either laptops or headphones? Round this to 2 decimals.
-- select extract the year, round(average of products name like laptops price in usd, 2)
SELECT DISTINCT product_name
FROM core.orders
ORDER BY 1;

SELECT EXTRACT(YEAR FROM purchase_ts) AS year,
  ROUND(AVG(usd_price),2) AS aov
FROM core.orders
WHERE LOWER(product_name) LIKE '%laptop%' OR 
  LOWER(product_name) LIKE '%headphones%'
GROUP BY 1
ORDER BY 1;

-- 1) What were the order counts, sales, and AOV for Macbooks sold in North America for each quarter across all years? 
-- need quarter from purchase date, count id, sum of usd, average where product is like macbook
-- join orders and customers on customer_id
-- join geo lookup and customers on country code

SELECT
  DATE_TRUNC(orders.purchase_ts, QUARTER) AS purchase_quarter,
  EXTRACT(QUARTER FROM orders.purchase_ts) AS quarter_num,
  COUNT(DISTINCT orders.id) AS order_counts,
  ROUND(SUM(orders.usd_price), 2) AS sales,
  ROUND(AVG(orders.usd_price), 2) AS aov
FROM core.orders
LEFT JOIN core.customers 
  ON customers.id = orders.customer_id
LEFT JOIN core.geo_lookup 
  ON geo_lookup.country_code = customers.country_code
WHERE LOWER(orders.product_name) LIKE "%macbook%" 
  AND geo_lookup.region = "NA"
GROUP BY 1,2
ORDER BY 1,2 DESC;

-- Bonus: What is the average quarterly order count and total sales for Macbooks sold in North America? (i.e. “For North America Macbooks, average of X units sold per quarter and Y in dollar sales per quarter”)
WITH quarterly_metrics AS (
  SELECT DATE_TRUNC(purchase_ts, quarter) as purchase_quarter,
    COUNT(DISTINCT orders.id) AS order_count,
    SUM(orders.usd_price) AS aov
  FROM core.orders
  LEFT JOIN core.customers 
    ON customers.id = orders.customer_id
  LEFT JOIN core.geo_lookup 
    ON geo_lookup.country_code = customers.country_code
  WHERE LOWER(orders.product_name) LIKE "%macbook%" 
    AND geo_lookup.region = "NA"
  GROUP BY 1
  ORDER BY 1 DESC
)
SELECT ROUND(AVG(order_count),2) as avg_qtr_order_count,
  ROUND(AVG(aov),2) AS avg_qtr_sales
FROM quarterly_metrics;

-- 2) For products purchased in 2022 on the website or products purchased on mobile in any year, which region has the average highest time to deliver? 
SELECT geo_lookup.region,
  AVG(DATE_DIFF(order_status.delivery_ts, order_status.purchase_ts, DAY)) as avg_time_to_deliver
FROM core.orders
LEFT JOIN core.order_status 
  ON order_status.order_id = orders.id
LEFT JOIN core.customers 
  ON customers.id = orders.customer_id
LEFT JOIN core.geo_lookup 
  ON geo_lookup.country_code = customers.country_code
WHERE (EXTRACT(YEAR FROM orders.purchase_ts) = 2022 AND purchase_platform = "website")
  OR purchase_platform = 'mobile app'
GROUP BY 1
ORDER BY 2 DESC;

-- 2.2  Rewrite this query for website purchases made in 2022 or Samsung purchases made in 2021, expressing time to deliver in weeks instead of days
SELECT DISTINCT product_name
FROM core.orders;

SELECT geo_lookup.region,
  AVG(DATE_DIFF(order_status.delivery_ts, order_status.purchase_ts, WEEK)) AS time_to_deliver_wk
FROM core.orders
LEFT JOIN core.customers 
  ON customers.id = orders.customer_id
LEFT JOIN core.geo_lookup 
  ON geo_lookup.country_code = customers.country_code
LEFT JOIN core.order_status 
  ON order_status.order_id = orders.id
WHERE (orders.purchase_platform = "website" AND EXTRACT(YEAR FROM orders.purchase_ts) = 2022)
  OR (LOWER(product_name) LIKE "%samsung%" AND EXTRACT(YEAR FROM orders.purchase_ts) = 2021)
GROUP BY 1
ORDER BY 2 DESC;

-- 3) What was the refund rate and refund count for each product overall?
SELECT CASE WHEN product_name = '27in"" 4k gaming monitor' THEN '27in 4K gaming monitor'
  ELSE product_name END AS product_clean,
  AVG(CASE WHEN refund_ts IS NOT NULL THEN 1 ELSE 0 END) as refund_rate,
  SUM(CASE WHEN refund_ts IS NOT NULL THEN 1 ELSE 0 END) as refund_count,
FROM core.orders 
LEFT JOIN core.order_status 
  ON orders.id = order_status.order_id
GROUP BY 1
ORDER BY 3 DESC;

-- What was the refund rate and refund count for each product per year?
SELECT EXTRACT(YEAR FROM orders.purchase_ts) as purchase_year,
  CASE WHEN product_name = '27in"" 4k gaming monitor' THEN '27in 4K gaming monitor' 
    ELSE product_name END AS product_clean,
  AVG(CASE WHEN refund_ts IS NOT NULL THEN 1 ELSE 0 END) as refund_rate,
  SUM(CASE WHEN refund_ts IS NOT NULL THEN 1 ELSE 0 END) as refund_count,
FROM core.orders 
LEFT JOIN core.order_status 
    ON orders.id = order_status.order_id
GROUP BY 1,2
ORDER BY 3 DESC;

-- Within each region, what is the most popular product? 
-- First clean the data and group by region and total orders
WITH sales_by_product AS (
  SELECT region, 
    CASE WHEN product_name = '27in"" 4k gaming monitor' THEN '27in 4K gaming monitor' 
      ELSE product_name END AS product_clean,
    COUNT(DISTINCT orders.id) AS total_orders
  FROM core.orders
  LEFT JOIN core.customers 
    ON customers.id = orders.customer_id
  LEFT JOIN core.geo_lookup
    ON geo_lookup.country_code = customers.country_code
  GROUP BY 1,2
),
-- Rank the products by total orders
ranked_product AS (
  SELECT *,
    ROW_NUMBER() OVER (PARTITION BY region ORDER BY total_orders DESC) as order_ranking
  FROM sales_by_product
  ORDER BY 4
)
-- Combine CTEs
SELECT *
FROM ranked_product
WHERE order_ranking = 1;

-- How does the time to make a purchase differ between loyalty customers vs. non-loyalty customers? 
select distinct loyalty_program
from core.customers;

SELECT customers.loyalty_program,
  AVG(DATE_DIFF(orders.purchase_ts, customers.created_on, DAY)) AS avg_time_to_purchase_days,
  AVG(DATE_DIFF(orders.purchase_ts, customers.created_on, MONTH)) AS avg_time_to_purchase_months
FROM core.orders
LEFT JOIN core.customers
  ON customers.id = orders.customer_id
GROUP BY 1;

-- Update this query to split the time to purchase per loyalty program, per purchase platform. Return the number of records to benchmark the severity of nulls.
SELECT customers.loyalty_program,
  purchase_platform,
  AVG(DATE_DIFF(orders.purchase_ts, customers.created_on, DAY)) AS avg_time_to_purchase_days,
  AVG(DATE_DIFF(orders.purchase_ts, customers.created_on, MONTH)) AS avg_time_to_purchase_months,
  COUNT(*) AS row_count
FROM core.orders
LEFT JOIN core.customers
  ON customers.id = orders.customer_id
GROUP BY 1, 2;
