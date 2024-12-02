/*Task 1. Create a view
Create a view called 'sales_revenue_by_category_qtr' that shows the film category and total sales revenue for the current quarter and year. The view should only display categories with at least one sale in the current quarter. 
Note: when the next quarter begins, it will be considered as the current quarter.*/

CREATE OR REPLACE VIEW sales_revenue_by_category_qtr AS
WITH category_sales AS (
    SELECT 
        c.name AS category_name,
        SUM(p.amount) AS total_revenue,
        EXTRACT(YEAR FROM p.payment_date) AS sale_year,
        EXTRACT(QUARTER FROM p.payment_date) AS sale_quarter
    FROM payment p
    JOIN rental r ON p.rental_id = r.rental_id
    JOIN inventory i ON r.inventory_id = i.inventory_id
    JOIN film f ON i.film_id = f.film_id
    JOIN film_category fc ON f.film_id = fc.film_id
    JOIN category c ON fc.category_id = c.category_id
    WHERE EXTRACT(YEAR FROM p.payment_date) = EXTRACT(YEAR FROM CURRENT_DATE)  -- Current year
      AND EXTRACT(QUARTER FROM p.payment_date) = EXTRACT(QUARTER FROM CURRENT_DATE) -- Current quarter
    GROUP BY c.name,sale_year, sale_quarter
)
SELECT 
    cs.category_name,
    cs.total_revenue
FROM category_sales cs
WHERE cs.total_revenue > 0  -- Filter categories with at least one sale
ORDER BY cs.total_revenue DESC; -- Sort by revenue in descending order

SELECT * FROM sales_revenue_by_category_qtr;

/*Task 2. Create a query language functions
Create a query language function called 'get_sales_revenue_by_category_qtr' that accepts one parameter representing the current quarter and year and returns the same result as the
 'sales_revenue_by_category_qtr' view.*/

CREATE OR REPLACE FUNCTION get_sales_revenue_by_category_qtr(
    p_year INT,          -- Year as input parameter
    p_quarter INT        -- Quarter (1 to 4) as input parameter
)
RETURNS TABLE (
    category_name VARCHAR,
    total_revenue DECIMAL
) AS
$$
BEGIN
    IF p_year IS NULL OR p_year < 0 THEN                         -- Checking error for input parameters
        RAISE EXCEPTION 'Invalid year: %', p_year
            USING HINT = 'Provide a non-negative year.';
    END IF;

    IF p_quarter NOT BETWEEN 1 AND 4 THEN                        -- Checking error for input parameters
        RAISE EXCEPTION 'Invalid quarter: %', p_quarter
            USING HINT = 'Quarter must be an integer between 1 and 4.';
    END IF;
    -- Execute the main query logic
    RETURN QUERY
    WITH category_sales AS (
        SELECT 
            c.name::VARCHAR AS category_name,
            SUM(p.amount) AS total_revenue
        FROM payment p
        JOIN rental r ON p.rental_id = r.rental_id
        JOIN inventory i ON r.inventory_id = i.inventory_id
        JOIN film f ON i.film_id = f.film_id
        JOIN film_category fc ON f.film_id = fc.film_id
        JOIN category c ON fc.category_id = c.category_id
        WHERE EXTRACT(YEAR FROM p.payment_date) = p_year  -- Filter by input year
          AND EXTRACT(QUARTER FROM p.payment_date) = p_quarter  -- Filter by input quarter
        GROUP BY c.name
    )
    SELECT 
        cs.category_name,
        cs.total_revenue
    FROM category_sales cs
    WHERE cs.total_revenue > 0
    ORDER BY cs.total_revenue DESC;  -- Sort by revenue in descending order
END;
$$ LANGUAGE plpgsql;

SELECT * 
FROM get_sales_revenue_by_category_qtr(2017, 2);


/*Task 3. Create procedure language functions
Create a function that takes a country as an input parameter and returns the most popular film in that specific country. 
The function should format the result set as follows:
                    Query (example):select * from core.most_popular_films_by_countries(array['Afghanistan','Brazil','United States’]);*/

CREATE OR REPLACE FUNCTION most_popular_films_by_countries(p_countries TEXT[])
RETURNS TABLE (
    country TEXT,
    film VARCHAR,
    rating VARCHAR,
    language VARCHAR,
    length INT,
    release_year INT
) AS $$
BEGIN
    IF p_countries IS NULL OR array_length(p_countries, 1) = 0 THEN
        RAISE EXCEPTION 'Input array of countries cannot be null or empty';
    END IF;

    RETURN QUERY
    WITH ranked_films AS (
        SELECT
            UPPER(co.country) ::TEXT AS country,
            f.title ::VARCHAR AS film,
            f.rating ::VARCHAR AS rating,
            l.name ::VARCHAR AS language,
            CAST(f.length AS INTEGER) AS length,  -- Cast length to INTEGER early
            f.release_year::INT AS release_year,
            COUNT(r.rental_id) AS rental_count,
            ROW_NUMBER() OVER (PARTITION BY UPPER(co.country) ORDER BY COUNT(r.rental_id) DESC) AS film_rank
        FROM rental r
        JOIN customer c ON r.customer_id = c.customer_id
        JOIN address a ON c.address_id = a.address_id
        JOIN city ci ON a.city_id = ci.city_id
        JOIN country co ON ci.country_id = co.country_id
        JOIN inventory i ON r.inventory_id = i.inventory_id
        JOIN film f ON i.film_id = f.film_id
        JOIN "language" l ON f.language_id = l.language_id
        WHERE UPPER(co.country) =  ANY (SELECT UPPER(c) FROM unnest(p_countries) c) -- Normalize input array to lowercase
        GROUP BY UPPER(co.country), f.title, f.rating, l.name, f.length, f.release_year
    )
    SELECT
        ranked_films.country,  -- Explicitly reference `country` from ranked_films
        ranked_films.film,
        ranked_films.rating,
        ranked_films.language,
        ranked_films.length,  -- Already cast to INTEGER
        ranked_films.release_year
    FROM ranked_films
    WHERE ranked_films.film_rank = 1;  -- Only select the most popular film for each country
END;
$$ LANGUAGE plpgsql;


select * from most_popular_films_by_countries(array['Afghanistan', 'BRAZIL', 'united states']);

/*Task 4. Create procedure language functions
Create a function that generates a list of movies available in stock based on a partial title match (e.g., movies containing the word 'love' in their title). 
The titles of these movies are formatted as '%...%', and if a movie with the specified title is not in stock, return a message indicating that it was not found.
The function should produce the result set in the following format (note: the 'row_num' field is an automatically generated counter field, starting from 1 and incrementing for each entry, e.g., 1, 2, ..., 100, 101, ...).

                    Query (example):select * from core.films_in_stock_by_title('%love%’);*/

CREATE OR REPLACE FUNCTION films_in_stock_by_title(
    search_pattern TEXT
) 
RETURNS TABLE (
	row_num INT,
    title TEXT,
    language TEXT,
    customer_name TEXT,
    rental_date DATE
) AS $$
BEGIN
    -- Return query to find movies without ROW_NUMBER() for debugging
    RETURN QUERY
    SELECT 
		CAST (ROW_NUMBER() OVER (ORDER BY f.title) AS INT) AS row_num,  -- Generate row_num based on title order
        f.title::TEXT,
        l."name"::TEXT AS language,  -- Cast language to TEXT
        (c.first_name || ' ' || c.last_name) AS customer_name,
        r.rental_date::DATE AS rental_date  -- Cast rental_date to DATE
    FROM 
        film f
        INNER JOIN inventory i ON f.film_id = i.film_id
        JOIN rental r ON r.inventory_id = i.inventory_id
        JOIN customer c ON r.customer_id = c.customer_id
        INNER JOIN "language" l ON l.language_id = f.language_id
    WHERE 
        UPPER(f.title) LIKE UPPER(search_pattern)
    ORDER BY f.title;
    -- Explicit check for no results found (post-query)
    IF NOT FOUND THEN
        RAISE NOTICE 'No movies found matching the title pattern "%".', search_pattern;
    END IF;
END;
$$ LANGUAGE plpgsql;

select * from films_in_stock_by_title('%love%');

 

/*Task 5. Create procedure language functions
Create a procedure language function called 'new_movie' that takes a movie title as a parameter and inserts a new movie with the given title in the film table. 
The function should generate a new unique film ID, set the rental rate to 4.99, the rental duration to three days, the replacement cost to 19.99. 
The release year and language are optional and by default should be current year and Klingon respectively. The function should also verify that the language exists 
in the 'language' table. Then, ensure that no such function has been created before; if so, replace it.*/

-- Create or replace the 'new_movie' function to handle duplicate checks, optional parameters, and error handling
CREATE OR REPLACE FUNCTION new_movie(
    p_title TEXT,                        -- Movie title (required)
    p_release_year INT DEFAULT EXTRACT(YEAR FROM CURRENT_DATE)::INT,  -- Default to current year
    p_language TEXT DEFAULT 'Klingon'     -- Default language is Klingon
)
RETURNS VOID AS $$
DECLARE
    v_language_id INT;
    v_duplicate_count INT;
BEGIN
    -- Check if the movie title already exists in the 'film' table
    SELECT COUNT(*) INTO v_duplicate_count
    FROM film
    WHERE UPPER(title) = UPPER(p_title);
    IF v_duplicate_count > 0 THEN
        RAISE EXCEPTION 'Movie with title "%" already exists in the film table.', p_title;
    END IF;
    -- Check if the provided language exists in the 'language' table
    SELECT language_id INTO v_language_id
    FROM "language"
    WHERE UPPER("name") = UPPER(p_language);
    -- If language does not exist, raise an exception
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Language "%" does not exist in the language table.', p_language;
    END IF;
    -- Insert the new movie into the 'film' table
    INSERT INTO film (title, release_year, language_id, rental_rate, rental_duration, replacement_cost)
    VALUES (
        p_title, 
        p_release_year, 
        v_language_id, 
        4.99,     -- Default rental rate
        3,        -- Default rental duration (3 days)
        19.99     -- Default replacement cost
    );
    RAISE NOTICE 'Movie "%" added successfully!', p_title;
END;
$$ LANGUAGE plpgsql;

--Testing----
SELECT new_movie('The New Adventure', 2024, 'English');
SELECT new_movie('The New Adventure', 2024, 'English'); -- should RAISE EXCEPTION
SELECT new_movie('Another Adventure', 2024, 'Elvish'); -- NEW movie WITH UNKNOWN LANGUAGE -- should reaise EXCEPTION
--Case sensitive checks:
SELECT new_movie('Adventure Time', 2024, 'english');  -- Should work
SELECT new_movie('adventure time', 2024, 'ENGLISH');  -- Should raise duplicate title exception


---TASK 6 ---------------------------------------------------------------------------------------------------------------------------------------------------------------
/*1.	Why does ‘rewards_report’ function return 0 rows? Correct and recreate the function, so that it's able to return rows properly.
Is there any function that can potentially be removed from the dvd_rental codebase? If so, which one and why?*/

CREATE OR REPLACE FUNCTION public.rewards_report(
    min_monthly_purchases INTEGER, 
    min_dollar_amount_purchased NUMERIC
) 
RETURNS SETOF customer
LANGUAGE plpgsql
SECURITY DEFINER
AS $function$
DECLARE
    last_month_start DATE;
    last_month_end DATE;
    rr RECORD;
    last_payment_date DATE;
BEGIN
    IF min_monthly_purchases <= 0 THEN
        RAISE EXCEPTION 'Minimum monthly purchases must be greater than 0';
    END IF;
    IF min_dollar_amount_purchased <= 0.00 THEN
        RAISE EXCEPTION 'Minimum dollar amount must be greater than 0';
    END IF;
    SELECT MAX(payment_date) INTO last_payment_date    -- Get the most recent payment date from the database
    FROM payment;
    IF last_payment_date IS NULL THEN    -- Check if there are any payments in the database
        RAISE EXCEPTION 'No payments found in the database.';
    END IF;
    last_month_start := date_trunc('month', last_payment_date - INTERVAL '1 month'); -- Calculate the date range for the previous month based on the most recent payment date
    last_month_end := (last_month_start + INTERVAL '1 month' - INTERVAL '1 day')::DATE;
    CREATE TEMP TABLE IF NOT EXISTS tmpCustomer (customer_id INTEGER PRIMARY KEY) ON COMMIT DROP; -- Create a temporary table for storing eligible customer IDs
    INSERT INTO tmpCustomer (customer_id)      -- Insert customer IDs meeting the reward criteria
    SELECT p.customer_id
    FROM payment p
    WHERE p.payment_date BETWEEN last_month_start AND last_month_end
    GROUP BY p.customer_id
    HAVING COUNT(p.customer_id) >= min_monthly_purchases
       AND SUM(p.amount) >= min_dollar_amount_purchased;
    -- Return customer details
    FOR rr IN
        SELECT c.*
        FROM tmpCustomer t
        JOIN customer c ON t.customer_id = c.customer_id
    LOOP
        RETURN NEXT rr;
    END LOOP;
    RETURN;
END
$function$;

SELECT * 
FROM public.rewards_report(3, 70.00);

/** The ‘get_customer_balance’ function describes the business requirements for calculating the client balance. Unfortunately, 
not all of them are implemented in this function. Try to change function using the requirements from the comments.*/

-- DROP FUNCTION public.get_customer_balance(int4, timestamptz);

CREATE OR REPLACE FUNCTION public.get_customer_balance(
    p_customer_id integer, 
    p_effective_date timestamp with time zone
) 
RETURNS numeric
LANGUAGE plpgsql
AS $function$
DECLARE
    v_rentfees DECIMAL(10, 2);  -- Rental fees paid initially
    v_overfees DECIMAL(10, 2);  -- Overdue fees
    v_replacement_fees DECIMAL(10, 2); -- Replacement fees for long-overdue rentals
    v_payments DECIMAL(10, 2);  -- Sum of payments made previously
BEGIN
    -- 1) Calculate rental fees for all previous rentals
    SELECT COALESCE(SUM(f.rental_rate), 0) INTO v_rentfees
    FROM film f
    JOIN inventory i ON f.film_id = i.film_id
    JOIN rental r ON i.inventory_id = r.inventory_id
    WHERE r.rental_date <= p_effective_date
      AND r.customer_id = p_customer_id;

    -- 2) Calculate overdue fees ($1 per day overdue)
    SELECT COALESCE(SUM(
        CASE 
            WHEN r.return_date IS NULL THEN 
                GREATEST(EXTRACT(DAY FROM (p_effective_date - r.rental_date)) - f.rental_duration, 0)
            WHEN (r.return_date - r.rental_date) > (f.rental_duration * '1 day'::interval) THEN 
                GREATEST(EXTRACT(DAY FROM (r.return_date - r.rental_date)) - f.rental_duration, 0)
            ELSE 0
        END
    ), 0) INTO v_overfees
    FROM rental r
    JOIN inventory i ON r.inventory_id = i.inventory_id
    JOIN film f ON i.film_id = f.film_id
    WHERE r.rental_date <= p_effective_date
      AND r.customer_id = p_customer_id;

    -- 3) Calculate replacement fees for rentals overdue by more than rental_duration * 2
    SELECT COALESCE(SUM(
        CASE
            WHEN r.return_date IS NULL AND (p_effective_date - r.rental_date) > (f.rental_duration * 2 * '1 day'::interval) THEN 
                f.replacement_cost
            WHEN r.return_date IS NOT NULL AND (r.return_date - r.rental_date) > (f.rental_duration * 2 * '1 day'::interval) THEN 
                f.replacement_cost
            ELSE 0
        END
    ), 0) INTO v_replacement_fees
    FROM rental r
    JOIN inventory i ON r.inventory_id = i.inventory_id
    JOIN film f ON i.film_id = f.film_id
    WHERE r.rental_date <= p_effective_date
      AND r.customer_id = p_customer_id;

    -- 4) Calculate total payments made by the customer before the effective date
    SELECT COALESCE(SUM(p.amount), 0) INTO v_payments
    FROM payment p
    WHERE p.payment_date <= p_effective_date
      AND p.customer_id = p_customer_id;

    -- Return the total balance
    RETURN (v_rentfees + v_overfees + v_replacement_fees) - v_payments;
END
$function$;

--To test the function:
SELECT public.get_customer_balance(1, '2024-11-01 00:00:00'::timestamptz);






