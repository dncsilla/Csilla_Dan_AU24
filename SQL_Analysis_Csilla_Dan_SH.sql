/*Task 3. Write SQL queries to perform the following tasks:*/
--Retrieve the total sales amount for each product category for a specific time period
-- Selected February of 2000

CREATE OR REPLACE FUNCTION get_total_sales_by_category(
    specified_year INT,
    specified_month INT
)
RETURNS TABLE (
    product_category VARCHAR,
    total_sales_amount NUMERIC
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        p.prod_category AS product_category,
        SUM(s.amount_sold) AS total_sales_amount
    FROM 
        sh.sales s
    JOIN 
        sh.products p ON s.prod_id = p.prod_id
    JOIN 
        sh.times t ON s.time_id = t.time_id
    WHERE 
        t.calendar_year = specified_year
        AND t.fiscal_month_number = specified_month
    GROUP BY 
        p.prod_category
    ORDER BY 
        total_sales_amount DESC;
END;
$$ LANGUAGE plpgsql;

--Testing it with February 2000:
SELECT * FROM get_total_sales_by_category(2000, 2);


--Calculate the average sales quantity by region for a particular product
CREATE OR REPLACE FUNCTION get_avg_sales_by_region(
    product_name VARCHAR
)
RETURNS TABLE (
    region VARCHAR,
    average_sales_quantity NUMERIC
) AS $$
BEGIN
    RETURN QUERY
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
        UPPER(p.prod_name) = UPPER(product_name) -- Case-insensitive comparison
    GROUP BY 
        c.country_name
    ORDER BY 
        average_sales_quantity DESC;
END;
$$ LANGUAGE plpgsql;

--Testing:
SELECT * FROM get_avg_sales_by_region('Standard Mouse');
SELECT * FROM get_avg_sales_by_region('standard mouse');
SELECT * FROM get_avg_sales_by_region('STANDARD MOUSE');

--Find the top five customers with the highest total sales amount
SELECT 
    cust.cust_id AS customer_id, 
    CONCAT(cust.cust_first_name, ' ', cust.cust_last_name) AS customer_name,
    SUM(s.amount_sold) AS total_sales_amount
FROM 
    sh.sales s
JOIN 
    sh.customers cust ON s.cust_id = cust.cust_id
GROUP BY 
    cust.cust_id, customer_name -- Group by unique ID and name
ORDER BY 
    total_sales_amount DESC
LIMIT 5;

