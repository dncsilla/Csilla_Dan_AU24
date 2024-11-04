
/*1.Choose your top-3 favorite movies and add them to the 'film' table (films with the title Film1, Film2, 
  etc - will not be taken into account and grade will be reduced)
  Fill in rental rates with 4.99, 9.99 and 19.99 and rental durations with 1, 2 and 3 weeks respectively.*/
WITH new_movie AS 
(
	SELECT
		'CITIZEN KANE' AS title, 
		4.99 AS rental_rate,
		1 AS rental_duration,
		(SELECT q.language_id FROM "language" AS q WHERE UPPER(q."name")= UPPER('English')) AS language_id 
		UNION ALL -- USING UNION ALL TO ...
	SELECT 
		'THE USUAL SUSPECTS'AS title, 
		9.99 AS rental_rate,
		2 AS rental_duration,
		(SELECT q.language_id FROM "language" AS q WHERE UPPER(q."name")= UPPER('English'))AS language_id 
		UNION ALL 
	SELECT 
		'SEVEN'AS title, 
		19.99 AS rental_rate,
		3 AS rental_duration,
		(SELECT q.language_id FROM "language" AS q WHERE q."name"= 'English')AS language_id
),
inserted_movie AS 
(
	INSERT INTO film (title,rental_rate,rental_duration,language_id)
	SELECT 
		t.title,t.rental_rate,t.rental_duration,t.language_id
	FROM 
		new_movie AS t
	WHERE 
		NOT EXISTS (
    		SELECT * 
    		FROM film f
    		WHERE f.title = t.title AND f.rental_rate = t.rental_rate)
	RETURNING title,rental_rate,rental_duration
)
SELECT * FROM inserted_movie;
/*2.Add the actors who play leading roles in your favorite movies to the 'actor' and 'film_actor' tables (6 or more actors in total).  
    Actors with the name Actor1, Actor2, etc - will not be taken into account and grade will be reduced*/
WITH new_actors AS (                      --CTE to list new actors along with their corresponding movie titles
	SELECT 
		'ORSON' AS first_name,
		'WELLES' AS last_name,
		'CITIZEN KANE' AS title
		UNION ALL                         -- USING UNION ALL since deduplication IS NOT needed
	SELECT 
		'KEVIN' AS first_name,
		'SPACEY' AS last_name,
		'THE USUAL SUSPECTS' AS title
		UNION ALL
	SELECT 
		'BENICIO' AS first_name,
		'DEL TORO' AS last_name,
		'THE USUAL SUSPECTS' AS title
		UNION ALL
	SELECT
		'GABRIEL'AS first_name,
		'BYRNE' AS last_name,
		'THE USUAL SUSPECTS' AS title
		UNION ALL
	SELECT 
		'STEPHEN'AS first_name,
		'BALDWIN' AS last_name,
		'THE USUAL SUSPECTS' AS title
		UNION ALL
	SELECT 
		'KEVIN'AS first_name,
		'POLLAK'AS last_name,
		'THE USUAL SUSPECTS' AS title
		UNION ALL
	SELECT 
		'BRAD'AS first_name,
		'PITT'AS last_name,
		'SEVEN' AS title
		UNION ALL
	SELECT 
		'MORGAN'AS first_name,
		'FREEMAN'AS last_name,
		'SEVEN' AS title
),
inserted_actors AS (
	INSERT INTO                              -- Insert records into film_actor to link each actor with their film.
		actor (first_name, last_name)
	SELECT 
		na.first_name, na.last_name
	FROM 
		new_actors AS na
	WHERE 
		NOT EXISTS (                         -- USING NOT EXISTS FOR NOT allowing duplication OF insertion
			SELECT *
			FROM actor a 
			WHERE a.first_name = na.first_name AND a.last_name = na.last_name
			)
	RETURNING actor_id, first_name,last_name
)
SELECT * FROM inserted_actors;
-- Associate actors with  films in film_actor:
WITH actor_film_mappings AS (                         -- CTE to map each actor to the appropriate film
    SELECT f.film_id, a.actor_id
    FROM film f
    LEFT JOIN actor a ON (a.first_name, a.last_name) IN ( -- USING LEFT JOIN TO find the VALUES FOR the actors ONLY, based ON FIRST name AND LAST name
        ('ORSON', 'WELLES'),
        ('KEVIN', 'SPACEY'),
        ('BENICIO', 'DEL TORO'),
        ('GABRIEL', 'BYRNE'),
        ('STEPHEN', 'BALDWIN'),
        ('KEVIN', 'POLLAK'),
        ('BRAD', 'PITT'),
        ('MORGAN', 'FREEMAN')
    )
    WHERE f.title IN ('CITIZEN KANE', 'THE USUAL SUSPECTS', 'SEVEN')
)
INSERT INTO film_actor (film_id, actor_id)           -- Insert records into film_actor to link each actor with their film FROM the cte.
SELECT film_id, actor_id
FROM actor_film_mappings
WHERE (film_id IS NOT NULL AND actor_id IS NOT NULL) -- Only non-null values are selected to ensure both film and actor records exist for each pairing.
RETURNING film_id, actor_id;

-- Task 3: Add movies to store inventory

WITH selected_films AS (                            -- creating CTE FOR the selected films
    SELECT f.film_id
    FROM film f
    WHERE f.title IN ('CITIZEN KANE', 'THE USUAL SUSPECTS', 'SEVEN')
)
INSERT INTO inventory (film_id, store_id)           -- inserting records INTO inevntory FROM the CTE
SELECT film_id, 2  -- Selected the store, which has store_id 2
FROM selected_films
RETURNING film_id, store_id;

-- Task 4: Update existing customer

WITH updated_customer AS (                         -- Creating CTE FOR the updated customer, WITH our details
    UPDATE customer
    SET first_name = 'Csilla',
        last_name = 'Dan',
        email = 'dancsilla@msn.com',
        address_id = (SELECT address_id FROM address LIMIT 1) -- Choosing an already existed address FROM adress table
    WHERE customer_id IN (                                    -- setting criteria
        SELECT c.customer_id
        FROM customer c
        WHERE (
            SELECT COUNT(*) FROM rental r WHERE r.customer_id = c.customer_id   --Criteria 1: Check that the customer has at least 43 rentals
        ) >= 43
        AND (
            SELECT COUNT(*) FROM payment p WHERE p.customer_id = c.customer_id  -- Criteria 2: Check that the customer has at least 43 payments
        ) >= 43
        AND NOT EXISTS (                                                        -- Criteria 3: Ensure that customer NOT EXISTS, NO duplication allowed.
        SELECT *
        FROM customer c
        WHERE UPPER(first_name) =UPPER('Csilla') AND UPPER(last_name) = UPPER('Dan')) -- USING upper() FOR 
    )
    RETURNING customer_id, first_name, last_name, email, address_id
)
SELECT * FROM updated_customer;

-- 5.Remove any records related to you (as a customer) from all tables except 'Customer' and 'Inventory'
DELETE FROM payment p                                                          -- deleting payment related DATA FOR SPECIFIC customer
WHERE p.customer_id =                                                          -- USING "=", because ONLY one value IS expected
	(SELECT c.customer_id 
	FROM customer c 
	WHERE UPPER(first_name) =UPPER('Csilla') AND UPPER(last_name) = UPPER('Dan'); -- USING upper not to be case-insensitive

DELETE FROM rental r                                                            -- deleting rental related DATA FOR SPECIFIC customer 
WHERE r.customer_id =                                                           -- USING "=", because ONLY one value IS expected
	(SELECT c.customer_id 
	FROM customer c 
	WHERE UPPER(first_name) =UPPER('Csilla') AND UPPER(last_name) = UPPER('Dan'); -- USING upper not to be case-insensitive

 /*6.Rent you favorite movies from the store they are in and pay for them (add corresponding records to the database 
   to represent this activity)
   (Note: to insert the payment_date into the table payment, you can create a new partition (see the scripts to install the 
   training database ) or add records for the first half of 2017)
 Retrieve customer ID based on the specified name directly in the query*/



WITH target_customer AS (                                    --CTE to retrieve customer ID based on the specified name directly in the query
    SELECT customer_id
    FROM customer
    WHERE UPPER(first_name) =UPPER('Csilla') AND UPPER(last_name) = UPPER('Dan'); -- USING upper not to be case-insensitive
    LIMIT 1
),
rented_movies AS (                                           -- CTE for insert rentals for each favorite movie and retrieve rental IDs
    INSERT INTO rental (inventory_id, customer_id, staff_id, rental_date)
    SELECT i.inventory_id, c.customer_id, 2, '2024-06-22 19:10:25-07' -- choosing staff id 2
    FROM inventory i
    CROSS JOIN target_customer c -- attaches the single customer_id to each row in the inventory table that matches the specified films, ensuring that all rentals are associated with the same customer.
    WHERE i.film_id IN (
        SELECT film_id 
        FROM film 
        WHERE title IN ('CITIZEN KANE', 'THE USUAL SUSPECTS', 'SEVEN')
    )
    RETURNING rental_id, customer_id, inventory_id -- Retrieve additional necessary fields
)
INSERT INTO payment (customer_id, staff_id, rental_id, amount, payment_date) -- Insert a payment for each rental using the returned rental IDs
SELECT r.customer_id, 
       1 AS staff_id, -- choosing staff_id 1
       r.rental_id, 
       f.rental_rate, -- Use film's rental_rate as payment amount
       '2017-06-01' AS payment_date -- payment date within the first half of 2017
FROM rented_movies r
JOIN inventory i ON r.inventory_id = i.inventory_id 
JOIN film f ON f.film_id = i.film_id
WHERE f.title IN ('CITIZEN KANE', 'THE USUAL SUSPECTS', 'SEVEN')
RETURNING payment_id; -- Retrieve the payment IDs 

