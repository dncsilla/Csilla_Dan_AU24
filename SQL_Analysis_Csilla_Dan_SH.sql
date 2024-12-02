/*Task 3. Write SQL queries to perform the following tasks:*/
--Retrieve the total sales amount for each product category for a specific time period
-- Selected February of 2000

SELECT 
    p.prod_category_id AS product_category,
    SUM(s.amount_sold) AS total_sales_amount
FROM 
    sh.sales s
JOIN 
    sh.products p ON s.prod_id = p.prod_id
JOIN 
    sh.times t ON s.time_id = t.time_id
WHERE 
    t.calendar_year = 2000 -- Selected February of 2000
    AND t.fiscal_month_number = 2 -- Selected February of 2000
GROUP BY 
    p.prod_category_id
ORDER BY 
    total_sales_amount DESC;


--Calculate the average sales quantity by region for a particular product
SELECT 
    c.country_name AS region,
    AVG(s.quantity_sold) AS average_sales_quantity
FROM 
    sh.sales s
JOIN 
    sh.customers cust ON s.cust_id = cust.cust_id
JOIN 
    sh.countries c ON cust.country_id = c.country_id
JOIN 
    sh.products p ON s.prod_id = p.prod_id
WHERE 
    p.prod_name = 'Standard Mouse'  --- Selected the Standard Mouse
GROUP BY 
    c.country_name
ORDER BY 
    average_sales_quantity DESC;

--Find the top five customers with the highest total sales amount
SELECT 
    CONCAT(cust.cust_first_name, ' ', cust.cust_last_name) AS customer_name,
    SUM(s.amount_sold) AS total_sales_amount
FROM 
    sh.sales s
JOIN 
    sh.customers cust ON s.cust_id = cust.cust_id
GROUP BY 
    customer_name
ORDER BY 
    total_sales_amount DESC
LIMIT 5;


