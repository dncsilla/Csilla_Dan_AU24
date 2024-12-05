/*Task 2. Implement role-based authentication model for dvd_rental database*/
--1. Create a new user with the username "rentaluser" and the password "rentalpassword". Give the user the ability to connect to the database but no other permissions.

DO $$
BEGIN
    -- Drop the role if it already exists
    IF EXISTS (
        SELECT 1 
        FROM pg_roles 
        WHERE rolname = 'rentaluser'
    ) THEN
    	ALTER USER rentaluser
		WITH LOGIN PASSWORD 'rentalpassword';
		-- Raise a notice for the update
        RAISE NOTICE 'Role "rentaluser" was updated.';
	  ELSE 
		CREATE USER rentaluser
   		WITH LOGIN PASSWORD 'rentalpassword'; -- Adjust attributes as needed
		-- Raise a notice for the creation
        RAISE NOTICE 'Role "rentaluser" was created.';
	  END IF;
END
$$ LANGUAGE plpgsql;

-- Check if the role was created.

SELECT rolname
FROM pg_roles
WHERE rolname = 'rentaluser';
GRANT CONNECT ON DATABASE dvdrental TO rentaluser;

--2. Grant "rentaluser" SELECT permission for the "customer" table. Сheck to make sure this permission works correctly—write a SQL query to select all customers.

GRANT SELECT ON TABLE customer TO rentaluser;

SET ROLE rentaluser; -- USING AS the newly created user
SELECT * FROM customer; -- SELECTing ALL COLUMNS FROM customer TABLE, TO CHECK IF it IS working
RESET ROLE; -- USING the DEFAULT role

--3. Create a new user group called "rental" and add "rentaluser" to the group. 

DO $$
BEGIN
    -- Check if the role exists
    IF EXISTS (
        SELECT 1 
        FROM pg_roles 
        WHERE rolname = 'rental'
    ) THEN
        -- Alter the role to ensure desired attributes
        ALTER ROLE rental;
    ELSE
        CREATE ROLE rental;
    END IF;
END
$$ LANGUAGE plpgsql;

-- Check if the role was created.

SELECT rolname
FROM pg_roles
WHERE rolname = 'rental';
GRANT rental TO rentaluser;-- Adding "rentaluser" to the group

--4. Grant the "rental" group INSERT and UPDATE permissions for the "rental" table. Insert a new row and update one existing row in the "rental" table under that role. 
ALTER ROLE rental WITH INHERIT; -- We have TO enable permission inheritance
GRANT INSERT, UPDATE ON TABLE rental TO rental;-- Grant `INSERT` and `UPDATE` permissions to the group for the `rental` TABLE
SET ROLE rentaluser;


-- Insert a new row with the rentaluser role:
-- NOTE for IDs to be not hardcoded we have to give permission SELECT to other tables for the rentaluser role ( which is against the task description), so I created a function and gave permission to that function to rentaluser.
RESET ROLE;   --- CREATE the FUNCTION AS the main USER.
CREATE OR REPLACE FUNCTION insert_rental_dynamically()
RETURNS TABLE (
    rental_id INT,
    rental_date DATE,
    inventory_id INT,
    customer_id INT,
    staff_id INT,
    return_date DATE
) AS $$
BEGIN
    RETURN QUERY
    INSERT INTO rental (rental_id, rental_date, inventory_id, customer_id, staff_id, return_date)
    SELECT 
        nextval('rental_rental_id_seq') AS rental_id,  -- Dynamically generate rental_id
        CURRENT_DATE::DATE AS rental_date,             -- Explicitly cast CURRENT_DATE to DATE
        (SELECT r.inventory_id FROM rental r LIMIT 1)::INTEGER, -- Fetch an inventory_id already present in the rental table
        (SELECT r.customer_id FROM rental r LIMIT 1)::INTEGER,  -- Explicitly cast customer_id to INTEGER
        (SELECT r.staff_id FROM rental r LIMIT 1)::INTEGER,     -- Fetch a staff_id already present in the rental table
        CURRENT_DATE + interval '5 days' AS return_date -- Calculate return_date dynamically
    WHERE NOT EXISTS (
        SELECT 1 
        FROM rental r
        WHERE r.inventory_id = (SELECT r2.inventory_id FROM rental r2 LIMIT 1)
          AND r.customer_id = (SELECT r2.customer_id FROM rental r2 LIMIT 1)
    )
    RETURNING rental.rental_id, rental.rental_date::DATE, rental.inventory_id, rental.customer_id::INTEGER, rental.staff_id::INTEGER, rental.return_date::DATE; -- Explicitly cast customer_id to INTEGER
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;


GRANT EXECUTE ON FUNCTION insert_rental_dynamically() TO rentaluser;
SET ROLE rentaluser;
SELECT * FROM insert_rental_dynamically();
SELECT * FROM rental ORDER BY rental_id DESC LIMIT 1;


--UPDATE the last added row
DO $$ 
DECLARE 
    v_last_rental_id INT;
BEGIN
    -- Fetch the rental_id of the last added row (most recent row by rental_id)
    SELECT rental_id INTO v_last_rental_id
    FROM rental
    ORDER BY rental_id DESC
    LIMIT 1;
    -- Check if the row exists and the return_date is not already the desired value
    IF EXISTS (
        SELECT 1
        FROM rental
        WHERE rental_id = v_last_rental_id 
    ) THEN
        -- Update the return_date if the condition is met
        UPDATE rental
        SET return_date = CURRENT_DATE + interval '10 days'
        WHERE rental_id = v_last_rental_id;
        -- Log a notice for debugging
        RAISE NOTICE 'Updated rental_id % with new return_date %', v_last_rental_id, CURRENT_DATE + interval '10 days';
    ELSE
        -- Log a notice if no update was necessary
        RAISE NOTICE 'No update required for rental_id %', v_last_rental_id;
    END IF;
END $$;

--Verifying the update:
SELECT * 
FROM rental
ORDER BY rental_id DESC
LIMIT 1;  -- Check the most recent rental entry

RESET ROLE;


--5. Revoke the "rental" group's INSERT permission for the "rental" table. Try to insert new rows into the "rental" table make sure this action is denied.
REVOKE INSERT ON TABLE rental FROM rental;

-- Test: Try inserting a new row as "rentaluser"
SET ROLE rentaluser;

INSERT INTO rental (rental_id, rental_date, inventory_id, customer_id, staff_id, return_date)
VALUES (32306, '2024-11-21', 2, 2, 1, '2024-11-30');

RESET ROLE;

--6. Create a personalized role for any customer already existing in the dvd_rental database. The name of the role name must be client_{first_name}_{last_name} 
--(omit curly brackets). The customer's payment and rental history must not be empty. 

SELECT customer_id, first_name, last_name  --Selecting a customer
FROM customer 
WHERE customer_id IN (
    SELECT DISTINCT customer_id FROM payment
) AND customer_id IN (
    SELECT DISTINCT customer_id FROM rental
) 
ORDER BY customer_id DESC
LIMIT 1;

DO $$ 
BEGIN
    -- create the role only if it doesn't exist
    BEGIN
        -- This creates the role if it doesn't already exist
        CREATE ROLE client_Austin_Cintron WITH NOLOGIN;
    EXCEPTION
        WHEN duplicate_object THEN
            -- If the role already exists, just update it
            RAISE NOTICE 'Role "client_Austin_Cintron" already exists. Updating attributes.';
            ALTER ROLE client_Austin_Cintron WITH NOLOGIN;
    END;
END $$ 
LANGUAGE plpgsql;
GRANT SELECT ON payment, rental TO client_Austin_Cintron; -- Assign  permissions for payment AND rental.


/*Task 3. Implement row-level security
Read about row-level security (https://www.postgresql.org/docs/12/ddl-rowsecurity.html) 
Configure that role so that the customer can only access their own data in the "rental" and "payment" tables. Write a query to make sure this user sees only their own data.*/


ALTER TABLE rental ENABLE ROW LEVEL SECURITY;-- Enable row-level security on the `rental` table
ALTER TABLE payment ENABLE ROW LEVEL SECURITY;-- Enable row-level security on the `payment` table

DO $$
BEGIN
   IF NOT EXISTS (                          -- Create the policy for the rental table if it does not already exist
      SELECT policyname
      FROM pg_policies
      WHERE schemaname = 'public' -- Replace 'public' with the appropriate schema if different
        AND tablename = 'rental'
        AND policyname = 'rental_customer_policy'
   ) THEN
      CREATE POLICY rental_customer_policy
      ON rental
      USING (customer_id = current_setting('app.current_customer')::INT);
   END IF;
   IF NOT EXISTS (                           -- Create the policy for the payment table if it does not already exist
      SELECT policyname
      FROM pg_policies
      WHERE schemaname = 'public' -- Replace 'public' with the appropriate schema if different
        AND tablename = 'payment'
        AND policyname = 'payment_customer_policy'
   ) THEN
      CREATE POLICY payment_customer_policy
      ON payment
      USING (customer_id = current_setting('app.current_customer')::INT);
   END IF;
END $$;


SET app.current_customer = '599'; 
-- Grant SELECT to all customers for both tables
SET ROLE client_Austin_Cintron;
-- Testing it
SELECT * FROM rental;
SELECT * FROM payment;








