/* 
TASK 1

Create a query to produce a sales report highlighting the top customers with the highest sales across different sales channels. This report should list the top 5 customers for each channel. Additionally, calculate a key performance indicator (KPI) called 'sales_percentage,' which represents the percentage of a customer's sales relative to the total sales within their respective channel.
Please format the columns as follows:
Display the total sales amount with two decimal places
Display the sales percentage with five decimal places and include the percent sign (%) at the end
Display the result for each channel in descending order of sales*/

 -- CTE to calculate total sales per customer and channel and the total channel sales
WITH customer_channel_sales AS (
    SELECT 
        s.channel_id,                               -- Channel ID from the sales table
        s.cust_id,                                  -- Customer ID from the sales table
        SUM(s.amount_sold) AS amount_sold,          -- Total sales amount per customer per channel
        SUM(SUM(s.amount_sold)) OVER (PARTITION BY s.channel_id) AS channel_total_sales -- Total sales for the channel
    FROM 
        sh.sales s                                  -- From the sales table in schema 'sh'
    GROUP BY 
        s.channel_id, s.cust_id                     -- Group by channel and customer
),
-- CTE to rank customers by their sales within each channel
ranked_sales AS (
    SELECT 
        c.channel_desc,                             -- Channel description
        cs.cust_id,                                 -- Customer ID
        cu.cust_last_name,                          -- Last name of the customer
        cu.cust_first_name,                         -- First name of the customer
        ROUND(cs.amount_sold, 2) AS amount_sold,    -- Total sales rounded to 2 decimals
        TO_CHAR((cs.amount_sold / cs.channel_total_sales) * 100, 'FM999,999,999.00000') || '%' AS sales_percentage,
        RANK() OVER (PARTITION BY cs.channel_id ORDER BY cs.amount_sold DESC) AS rank -- Rank customers within each channel
    FROM 
        customer_channel_sales cs                   -- From the combined CTE
    JOIN 
        sh.channels c ON cs.channel_id = c.channel_id -- Join with channels table to get channel descriptions
    JOIN 
        sh.customers cu ON cs.cust_id = cu.cust_id  -- Join with customers table to get customer details
)
-- Final query to filter the top 5 customers for each channel
SELECT 
    channel_desc,
    cust_id,
    cust_first_name,
    cust_last_name,
    amount_sold,
    sales_percentage                              -- Display as .xxxxx%
FROM 
    ranked_sales
WHERE 
    rank <= 5                                      -- Only include the top 5 customers per channel
ORDER BY 
    channel_desc, amount_sold desc;                -- Sort results by channel description and descending sales
/*
 Create a query to retrieve data for a report that displays the total sales for all products in the Photo category in the Asian region for the year 2000. Calculate the overall report total and name it 'YEAR_SUM'
Display the sales amount with two decimal places
Display the result in descending order of 'YEAR_SUM'
For this report, consider exploring the use of the crosstab function. Additional details and guidance can be found at this link */


-- Enable the tablefunc extension to use the crosstab function
CREATE EXTENSION IF NOT EXISTS tablefunc;

-- Main query to fetch the total sales for products in the "Photo" category in the Asian region for the year 2000
SELECT *,
       (COALESCE(q1, 0) + COALESCE(q2, 0) + COALESCE(q3, 0) + COALESCE(q4, 0)) AS year_sum            -- Calculate the overall sum of sales across all quarters, replacing NULL with 0
FROM crosstab(
    $$ 
    -- Subquery to get the sales data for each product in the "Photo" category in the Asian region for the year 2000
    SELECT 
        p.prod_name,                             -- Product name
        EXTRACT(QUARTER FROM t.time_id) AS quarter,  -- Extract the quarter from the time ID
        SUM(s.amount_sold) AS total_sales        -- Total sales amount for the product in the specified quarter
    FROM 
        sh.sales s                                -- Sales table in schema 'sh'
    JOIN 
        sh.products p ON s.prod_id = p.prod_id    -- Join with products table to get product details
    JOIN 
        sh.times t ON s.time_id = t.time_id       -- Join with times table to get the year information
    JOIN 
        sh.channels c ON s.channel_id = c.channel_id  -- Join with channels table to get channel info
    JOIN 
        sh.customers c2 ON s.cust_id = c2.cust_id  -- Join with customers table to get customer details
    JOIN 
        sh.countries co ON c2.country_id = co.country_id  -- Join with countries table to get region info
    WHERE 
        p.prod_category = 'Photo'                     -- Filter products for the "Photo" category
        AND co.country_region = 'Asia'                -- Filter for the "Asian" region
        AND EXTRACT(YEAR FROM t.time_id) = 2000       -- Filter for the year 2000
    GROUP BY 
        p.prod_name, EXTRACT(QUARTER FROM t.time_id) -- Group by product name and quarter
    ORDER BY 
        p.prod_name, EXTRACT(QUARTER FROM t.time_id) -- Order by product name and quarter
    $$,
    $$ 
    -- The second parameter is the column definition for the crosstab output
    SELECT DISTINCT EXTRACT(QUARTER FROM t.time_id) AS quarter
    FROM sh.times t 
    WHERE EXTRACT(YEAR FROM t.time_id) = 2000       -- Define the columns for each quarter
    ORDER BY EXTRACT(QUARTER FROM t.time_id)
    $$ 
) AS ct(
    product_name text,       -- Column to hold the product names
    q1 numeric,              -- Column for total sales in Q1
    q2 numeric,              -- Column for total sales in Q2
    q3 numeric,              -- Column for total sales in Q3
    q4 numeric               -- Column for total sales in Q4
)
ORDER BY year_sum DESC;                                -- Order the results by the yearly sum in descending order
/*
Create a query to generate a sales report for customers ranked in the top 300 based on total sales in the years 1998, 1999, and 2001. The report should be categorized based on sales channels, and separate calculations should be performed for each channel.
Retrieve customers who ranked among the top 300 in sales for the years 1998, 1999, and 2001
Categorize the customers based on their sales channels
Perform separate calculations for each sales channel
Include in the report only purchases made on the channel specified
Format the column so that total sales are displayed with two decimal places*/
WITH yearly_ranked_sales AS (
    -- Step 1: Rank customers by total sales for each year and channel
    SELECT
        c.channel_desc,                    -- Sales channel
        s.cust_id,                         -- Customer ID
        c2.cust_last_name,                 -- Customer's last name
        c2.cust_first_name,                -- Customer's first name
        t.fiscal_year,                     -- Year of sales
        SUM(s.amount_sold) AS total_sales, -- Total sales by year
        RANK() OVER (
            PARTITION BY c.channel_desc, t.fiscal_year 
            ORDER BY SUM(s.amount_sold) DESC
        ) AS sales_rank                    -- Rank customers within each year and channel
    FROM 
        sh.sales s
    JOIN 
        sh.channels c ON s.channel_id = c.channel_id
    JOIN 
        sh.customers c2 ON s.cust_id = c2.cust_id
    JOIN 
        sh.times t ON s.time_id = t.time_id
    WHERE 
        t.fiscal_year IN (1998, 1999, 2001) -- Filter for the years 1998, 1999, and 2001
    GROUP BY 
        c.channel_desc, s.cust_id, c2.cust_last_name, c2.cust_first_name, t.fiscal_year
),
qualified_customers AS (
    -- Step 2: Find customers ranked in the top 300 for all three years
    SELECT 
        channel_desc, 
        cust_id, 
        cust_last_name, 
        cust_first_name
    FROM 
        yearly_ranked_sales
    WHERE 
        sales_rank <= 300
    GROUP BY 
        channel_desc, cust_id, cust_last_name, cust_first_name
    HAVING 
        COUNT(DISTINCT fiscal_year) = 3 -- Ensure they were in the top 300 in all three years
),
final_sales AS (
    -- Step 3: Calculate total sales for qualified customers by channel
    SELECT 
        c.channel_desc,                    -- Sales channel
        s.cust_id,                         -- Customer ID
        c2.cust_last_name,                 -- Customer's last name
        c2.cust_first_name,                -- Customer's first name
        SUM(s.amount_sold) AS total_sales  -- Total sales for all years combined
    FROM 
        sh.sales s
    JOIN 
        sh.channels c ON s.channel_id = c.channel_id
    JOIN 
        sh.customers c2 ON s.cust_id = c2.cust_id
    JOIN 
        sh.times t ON s.time_id = t.time_id
    JOIN 
        qualified_customers qc ON 
            s.cust_id = qc.cust_id AND c.channel_desc = qc.channel_desc
    WHERE 
        t.fiscal_year IN (1998, 1999, 2001) -- Filter for the specified years
    GROUP BY 
        c.channel_desc, s.cust_id, c2.cust_last_name, c2.cust_first_name
)
-- Step 4: Format the result and output the final report
SELECT 
    channel_desc, 
    cust_id, 
    cust_last_name, 
    cust_first_name, 
    TO_CHAR(total_sales, 'FM999,999,999.00') AS amount_sold
FROM 
    final_sales
ORDER BY 
    channel_desc, total_sales DESC;

    
    
/*
 Create a query to generate a sales report for January 2000, February 2000, and March 2000 specifically for the Europe and Americas regions.
Display the result by months and by product category in alphabetical order.
 */


 SELECT DISTINCT
    TO_CHAR(t.calendar_year, 'FM0000') || '-' || LPAD(t.calendar_month_number::TEXT, 2, '0') AS calendar_month_desc,  -- Format month as "yyyy-mm"
    p.prod_category,                                                                    -- Product category
    TO_CHAR(SUM(CASE WHEN UPPER(co.country_region) = UPPER('AMERICAS') THEN s.amount_sold ELSE 0 END) 
            OVER (PARTITION BY t.calendar_year, t.calendar_month_number, p.prod_category), 
            'FM999,999,999') AS "Americas sales",                                   -- Americas sales using window function
    TO_CHAR(SUM(CASE WHEN UPPER(co.country_region) = UPPER('EUROPE') THEN s.amount_sold ELSE 0 END) 
            OVER (PARTITION BY t.calendar_year, t.calendar_month_number, p.prod_category), 
            'FM999,999,999') AS "Europe sales"                                      -- Europe sales using window function
FROM
    sh.sales s
JOIN
    sh.products p ON s.prod_id = p.prod_id                                              -- Join with products table
JOIN
    sh.times t ON s.time_id = t.time_id                                                 -- Join with times table
JOIN
    sh.customers c ON s.cust_id = c.cust_id                                             -- Join with customers table
JOIN
    sh.countries co ON c.country_id = co.country_id                                     -- Join with countries table
WHERE
    t.fiscal_year = 2000                                                                -- Filter for year 2000
    AND t.calendar_month_number IN (1, 2, 3)                                            -- Filter for Jan, Feb, Mar
ORDER BY
    calendar_month_desc, p.prod_category;                                              -- Order by formatted month and product category








