/*Task 2. Implement role-based authentication model for dvd_rental database*/
--1. Create a new user with the username "rentaluser" and the password "rentalpassword". Give the user the ability to connect to the database but no other permissions.

CREATE USER rentaluser WITH PASSWORD 'rentalpassword';
GRANT CONNECT ON DATABASE dvdrental TO rentaluser;

--2. Grant "rentaluser" SELECT permission for the "customer" table. Сheck to make sure this permission works correctly—write a SQL query to select all customers.

GRANT SELECT ON TABLE customer TO rentaluser;

SET ROLE rentaluser; -- USING AS the newly created user
SELECT * FROM customer; -- SELECTing ALL COLUMNS FROM customer TABLE, TO CHECK IF it IS working
RESET ROLE; -- USING the DEFAULT role

--3. Create a new user group called "rental" and add "rentaluser" to the group. 

CREATE ROLE rental;
GRANT rental TO rentaluser;-- Adding "rentaluser" to the group

--4. Grant the "rental" group INSERT and UPDATE permissions for the "rental" table. Insert a new row and update one existing row in the "rental" table under that role. 
ALTER ROLE rental WITH INHERIT; -- We have TO enable permission inheritance
GRANT INSERT, UPDATE ON TABLE rental TO rental;-- Grant `INSERT` and `UPDATE` permissions to the group for the `rental` TABLE
SET ROLE rentaluser;


INSERT INTO rental (rental_id, rental_date, inventory_id, customer_id, staff_id, return_date) -- Insert a new row into the "rental" table
VALUES (32305, '2024-11-20', 1, 1, 1, '2024-11-25'); -- IF we want TO ADD ROWS, which ARE NOT hardcoded, we have TO GRANT SELECT ALSO FOR the roles.


UPDATE rental SET return_date = '2024-11-28' WHERE rental_id = 32305;-- Update an existing row in the "rental" table

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

CREATE ROLE client_Austin_Cintron;
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


SET app.current_customer = '599'; -- Set the current customer in the session,replace '1' with the current customer's ID
-- Grant SELECT to all customers for both tables
SET ROLE client_Austin_Cintron;
-- Testing it
SELECT * FROM rental;
SELECT * FROM payment;








