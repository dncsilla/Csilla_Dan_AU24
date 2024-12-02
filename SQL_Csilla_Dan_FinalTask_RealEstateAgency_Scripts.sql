/*3. Create a physical database with a separate database and schema and give it an appropriate domain-related name. 
Create relationships between tables using primary and foreign keys.
Use ALTER TABLE to add at least 5 check constraints across the tables to restrict certain values, as example 
date to be inserted, which must be greater than July 1, 2024
inserted measured value that cannot be negative
inserted value that can only be a specific value
unique
not null

Give meaningful names to your CHECK constraints. 
Use appropriate data types for each column and apply DEFAULT, STORED AS and GENERATED ALWAYS AS columns as required.*/



CREATE DATABASE real_estate_agency;
CREATE SCHEMA real_estate;

-- Creating tables:
-- Creating Agent table
CREATE TABLE IF NOT EXISTS real_estate.agent (
    agent_id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,                     -- Auto-incrementing primary key
    agent_name VARCHAR(100) NOT NULL,                 -- Agent's name
    email VARCHAR(150) UNIQUE NOT NULL,              -- Unique email for the agent
    phone VARCHAR(20) NOT NULL                      -- Agent's contact phone number
);
--Create Client table
CREATE TABLE IF NOT EXISTS real_estate.client (
    client_id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,                    -- Auto-incrementing primary key
    client_name VARCHAR(100) NOT NULL,                -- Client's full name
    email VARCHAR(150) UNIQUE NOT NULL,              -- Client's unique email address
    phone VARCHAR(20) NOT NULL                      -- Client's phone number
);
--Create Property table
CREATE TABLE IF NOT EXISTS real_estate.property (
    property_id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,                  -- Auto-incrementing primary key
    address VARCHAR(200) NOT NULL,                   -- Property address
    price DECIMAL(10, 2) NOT NULL,                   -- Price of the property
    agent_id INT NOT NULL,                           -- Foreign key to agent managing the property
    CONSTRAINT fk_property_agent FOREIGN KEY (agent_id) REFERENCES real_estate.agent(agent_id) 
);
-- Create Transaction table
CREATE TABLE IF NOT EXISTS real_estate."transaction" (
    transaction_id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,               -- Auto-incrementing primary key
    client_id INT NOT NULL,                          -- Foreign key to the client involved
    property_id INT NOT NULL,                        -- Foreign key to the property involved
    date DATE NOT NULL,                              -- Transaction date
    amount DECIMAL(10, 2) NOT NULL,                  -- Transaction amount
    CONSTRAINT fk_transaction_client FOREIGN KEY (client_id) REFERENCES real_estate.client(client_id),
    CONSTRAINT fk_transaction_property FOREIGN KEY (property_id) REFERENCES real_estate.property(property_id)
);
--Create Visit table
CREATE TABLE IF NOT EXISTS real_estate.visit (
    visit_id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,                     -- Auto-incrementing primary key
    client_id INT NOT NULL,                          -- Foreign key to the client visiting the property
    property_id INT NOT NULL,                        -- Foreign key to the property being visited
    visit_date DATE NOT NULL,                        -- Visit date
    CONSTRAINT fk_visit_client FOREIGN KEY (client_id) REFERENCES real_estate.client(client_id),
    CONSTRAINT fk_visit_property FOREIGN KEY (property_id) REFERENCES real_estate.property(property_id)
);
--Create Payment table
CREATE TABLE IF NOT EXISTS real_estate.payment (
    payment_id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,                   -- Auto-incrementing primary key
    transaction_id INT NOT NULL,                     -- Foreign key to the associated transaction
    payment_date DATE NOT NULL,                      -- Date of the payment
    amount_paid DECIMAL(10, 2) NOT NULL,             -- Amount paid
    CONSTRAINT fk_payment_transaction FOREIGN KEY (transaction_id) REFERENCES real_estate.transaction(transaction_id)
);
--
-- Add a CHECK constraint on property prices 
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM pg_constraint
        WHERE conname = 'chk_price_positive'  -- Constraint name
          AND conrelid = 'real_estate.property'::regclass  -- Table name
    ) THEN
        ALTER TABLE real_estate.property
        ADD CONSTRAINT chk_price_positive CHECK (price > 0);
    END IF;
END $$;
-- Add a CHECK constraint on transaction amounts (if not already applied)
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM pg_constraint
        WHERE conname = 'chk_transaction_amount'  -- Constraint name
          AND conrelid = 'real_estate.transaction'::regclass  -- Table name
    ) THEN
        ALTER TABLE real_estate.transaction
        ADD CONSTRAINT chk_transaction_amount CHECK (amount > 0);
    END IF;
END $$;
-- Add a CHECK constraint on the visit_date to ensure it's not a future date
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM pg_constraint
        WHERE conname = 'chk_visit_date'  -- Constraint name
          AND conrelid = 'real_estate.visit'::regclass  -- Table name
    ) THEN
        ALTER TABLE real_estate.visit
        ADD CONSTRAINT chk_visit_date CHECK (visit_date <= CURRENT_DATE);
    END IF;
END $$;

-- Ensure payment amount is positive (if not already applied)
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM pg_constraint
        WHERE conname = 'chk_payment_positive'  -- Constraint name
          AND conrelid = 'real_estate.payment'::regclass  -- Table name
    ) THEN
        ALTER TABLE real_estate.payment
        ADD CONSTRAINT chk_payment_positive CHECK (amount_paid > 0);
    END IF;
END $$;

-- Add check constraint for Date must be after July 1, 2024
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM pg_constraint
        WHERE conname = 'chk_transaction_date'  -- Constraint name
          AND conrelid = 'real_estate.transaction'::regclass  -- Table name
    ) THEN
        ALTER TABLE real_estate."transaction"
        ADD CONSTRAINT chk_transaction_date CHECK (date >= '2024-07-01');
    END IF;
END $$;


/*4. Populate the tables with the sample data generated, ensuring each table has at least 6+ rows (for a total of 36+ rows in all the tables) for the last 3 months.
Create DML scripts for insert your data. 
Ensure that the DML scripts do not include values for surrogate keys, as these keys should be generated by the database during runtime. 
Also, ensure that any DEFAULT values required are specified appropriately in the DML scripts. 
These DML scripts should be designed to successfully adhere to all previously defined constraints*/



-- Insert agents if they do not already exist
WITH inserted_agents AS (
        INSERT INTO real_estate.agent (agent_name, email, phone)
        SELECT agent_name, email, phone
        FROM (
        	SELECT 'John Doe', 'john.doe@agency.com', '5551111111'
        	UNION ALL
        	SELECT 'Jane Smith', 'jane.smith@agency.com', '5552222222'
        	UNION ALL
        	SELECT 'Sarah Taylor', 'sarah.taylor@agency.com', '5553333333'
        	UNION ALL 
        	SELECT 'Michael Brown', 'michael.brown@agency.com', '5554444444'
        	UNION ALL 
        	SELECT 'David Clark', 'david.clark@agency.com', '5555555555'
        	UNION ALL
        	SELECT 'Linda Green', 'linda.green@agency.com', '5556666666'
        ) AS agent_data(agent_name, email, phone)
        WHERE NOT EXISTS (
            SELECT 1 
            FROM real_estate.agent a 
            WHERE a.email = agent_data.email
        )
        RETURNING agent_id, agent_name, email, phone
    )
SELECT * FROM inserted_agents;

-- Insert clients if they do not already exist
WITH  inserted_clients AS (
        INSERT INTO real_estate.client (client_name, email, phone)
        SELECT client_name, email, phone
        FROM (
            SELECT 'Alice Johnson', 'alice.johnson@mail.com', '5557777778'
            UNION ALL 
            SELECT 'Bob Brown', 'bob.brown@mail.com', '5558888888'
            UNION ALL 
            SELECT 'Carol Davis', 'carol.davis@mail.com', '5559999999'
            UNION ALL 
            SELECT 'Daniel Moore', 'daniel.moore@mail.com', '5551010101'
            UNION ALL 
            SELECT 'Eva Roberts', 'eva.roberts@mail.com', '5552020202'
            UNION ALL 
            SELECT 'Frank Harris', 'frank.harris@mail.com', '5553030303'
        ) AS client_data(client_name, email, phone)
        WHERE NOT EXISTS (
            SELECT 1 
            FROM real_estate.client c 
            WHERE c.email = client_data.email
        )
        RETURNING client_id, client_name, email, phone
    )
SELECT * FROM inserted_clients;
--Insert properties
WITH new_property AS (
	INSERT INTO real_estate.property (address, price, agent_id)
    SELECT address, price, agent_id
    FROM (
        SELECT '123 Elm Street', 250000.00, 1
        UNION ALL 
        SELECT '456 Oak Avenue', 300000.00, 2
        UNION ALL 
        SELECT '789 Pine Road', 200000.00, 3
        UNION ALL 
        SELECT '101 Maple Lane', 350000.00, 4
        UNION ALL 
        SELECT '202 Birch Street', 400000.00, 5
        UNION ALL 
        SELECT '303 Cedar Boulevard', 450000.00, 6
    ) AS properties(address, price, agent_id)
    WHERE NOT EXISTS (
        SELECT 1 FROM real_estate.property p WHERE p.address = properties.address
    )
    RETURNING agent_id
)
SELECT * FROM new_property;

--Insert transactions
WITH transaction_data AS (
    SELECT c.client_id, p.property_id, '2024-07-15'::DATE, 250000.00 AS amount
    FROM real_estate.client c, real_estate.property p
    WHERE c.client_name = 'Alice Johnson' AND p.address = '123 Elm Street'
    UNION
    SELECT c.client_id, p.property_id, '2024-08-01'::DATE, 300000.00
    FROM real_estate.client c, real_estate.property p
    WHERE c.client_name = 'Bob Brown' AND p.address = '456 Oak Avenue'
    UNION
    SELECT c.client_id, p.property_id, '2024-08-10'::DATE, 200000.00
    FROM real_estate.client c, real_estate.property p
    WHERE c.client_name = 'Carol Davis' AND p.address = '789 Pine Road'
    UNION
    SELECT c.client_id, p.property_id, '2024-08-20'::DATE, 350000.00
    FROM real_estate.client c, real_estate.property p
    WHERE c.client_name = 'Daniel Moore' AND p.address = '101 Maple Lane'
    UNION
    SELECT c.client_id, p.property_id, '2024-09-05'::DATE, 400000.00
    FROM real_estate.client c, real_estate.property p
    WHERE c.client_name = 'Eva Roberts' AND p.address = '202 Birch Street'
    UNION
    SELECT c.client_id, p.property_id, '2024-09-10'::DATE, 450000.00
    FROM real_estate.client c, real_estate.property p
    WHERE c.client_name = 'Frank Harris' AND p.address = '303 Cedar Boulevard'
)
INSERT INTO real_estate.transaction (client_id, property_id, date, amount)
SELECT * FROM transaction_data
WHERE NOT EXISTS (
    SELECT 1 FROM real_estate.transaction t
    WHERE t.client_id = transaction_data.client_id AND t.property_id = transaction_data.property_id
)
RETURNING *;
--Insert visits
WITH visit_data AS (
    SELECT c.client_id, p.property_id, '2024-07-10'::DATE AS visit_date
    FROM real_estate.client c, real_estate.property p
    WHERE c.client_name = 'Alice Johnson' AND p.address = '123 Elm Street'
    UNION
    SELECT c.client_id, p.property_id, '2024-07-20'::DATE
    FROM real_estate.client c, real_estate.property p
    WHERE c.client_name = 'Bob Brown' AND p.address = '456 Oak Avenue'
    UNION
    SELECT c.client_id, p.property_id, '2024-07-25'::DATE
    FROM real_estate.client c, real_estate.property p
    WHERE c.client_name = 'Carol Davis' AND p.address = '789 Pine Road'
    UNION
    SELECT c.client_id, p.property_id, '2024-08-15'::DATE
    FROM real_estate.client c, real_estate.property p
    WHERE c.client_name = 'Daniel Moore' AND p.address = '101 Maple Lane'
    UNION
    SELECT c.client_id, p.property_id, '2024-08-18'::DATE
    FROM real_estate.client c, real_estate.property p
    WHERE c.client_name = 'Eva Roberts' AND p.address = '202 Birch Street'
    UNION
    SELECT c.client_id, p.property_id, '2024-09-01'::DATE
    FROM real_estate.client c, real_estate.property p
    WHERE c.client_name = 'Frank Harris' AND p.address = '303 Cedar Boulevard'
)
INSERT INTO real_estate.visit (client_id, property_id, visit_date)
SELECT * FROM visit_data
WHERE NOT EXISTS (
    SELECT 1 FROM real_estate.visit v
    WHERE v.client_id = visit_data.client_id AND v.property_id = visit_data.property_id
)
RETURNING *;
-- Insert payments
WITH payment_data AS (
    SELECT t.transaction_id, '2024-07-20'::DATE AS payment_date, 125000.00 AS amount_paid
    FROM real_estate.transaction t WHERE t.transaction_id = 1
    UNION
    SELECT t.transaction_id, '2024-07-30'::DATE, 125000.00
    FROM real_estate.transaction t WHERE t.transaction_id = 1
    UNION
    SELECT t.transaction_id, '2024-08-10'::DATE, 150000.00
    FROM real_estate.transaction t WHERE t.transaction_id = 2
    UNION
    SELECT t.transaction_id, '2024-08-20'::DATE, 150000.00
    FROM real_estate.transaction t WHERE t.transaction_id = 2
    UNION
    SELECT t.transaction_id, '2024-09-05'::DATE, 200000.00
    FROM real_estate.transaction t WHERE t.transaction_id = 3
    UNION
    SELECT t.transaction_id, '2024-09-10'::DATE, 350000.00
    FROM real_estate.transaction t WHERE t.transaction_id = 4
)
INSERT INTO real_estate.payment (transaction_id, payment_date, amount_paid)
SELECT * FROM payment_data
WHERE NOT EXISTS (
    SELECT 1 FROM real_estate.payment p
    WHERE p.transaction_id = payment_data.transaction_id AND p.payment_date = payment_data.payment_date
)
RETURNING *;

/*5. Create the following functions.
5.1 Create a function that updates data in one of your tables. This function should take the following input arguments:
The primary key value of the row you want to update
The name of the column you want to update
The new value you want to set for the specified column

This function should be designed to modify the specified row in the table, updating the specified column with the new value.*/
CREATE OR REPLACE FUNCTION update_property(
    p_property_id INT,           -- Primary key value (property_id)
    p_column_name TEXT,          -- Column name to update (e.g., 'price')
    p_new_value TEXT             -- New value to set in the column
)
RETURNS VOID AS $$
DECLARE
    v_column_type TEXT;
BEGIN
    -- Check if the column exists
    IF NOT EXISTS (
        SELECT 1
        FROM information_schema.columns
        WHERE table_name = 'property'
          AND column_name = p_column_name
    ) THEN
        -- Raise an exception if the column doesn't exist
        RAISE EXCEPTION 'Column "%" does not exist in the "property" table', p_column_name;
    END IF;
    -- Retrieve the data type of the column
    SELECT data_type INTO v_column_type
    FROM information_schema.columns
    WHERE table_name = 'property'
      AND column_name = p_column_name;
    -- Dynamically cast p_new_value to the correct data type
    IF v_column_type = 'numeric' THEN
        -- For numeric columns (like price), cast p_new_value to NUMERIC
        EXECUTE format(
            'UPDATE real_estate.property SET %I = $1 WHERE property_id = $2',
            p_column_name
        )
        USING p_new_value::NUMERIC, p_property_id;
    ELSIF v_column_type = 'text' THEN
        -- For text columns, no casting is needed
        EXECUTE format(
            'UPDATE real_estate.property SET %I = $1 WHERE property_id = $2',
            p_column_name
        )
        USING p_new_value, p_property_id;
    ELSIF v_column_type = 'date' THEN
        -- For date columns, cast p_new_value to DATE
        EXECUTE format(
            'UPDATE real_estate.property SET %I = $1 WHERE property_id = $2',
            p_column_name
        )
        USING p_new_value::DATE, p_property_id;
    ELSE
        -- Raise an exception if the column's data type is not handled
        RAISE EXCEPTION 'Data type "%" is not supported for column "%"', v_column_type, p_column_name;
    END IF;
    -- Raise a notice to indicate the update was successful
    RAISE NOTICE 'Property with property_id % has been updated. Column "%" is now set to "%".',
        p_property_id, p_column_name, p_new_value;
END;
$$ LANGUAGE plpgsql;

-- TEST :Update the "price" column in the "properties" table for a specific property_id
-- Example: Update the "price" column in the "property" table for a specific property_id
SELECT update_property(
    1,                        -- property_id (Primary key value)
    'price',                  -- Column name to update
    '350000'                  -- New value to set (price = 350000)
);
--Verifying : Check the updated row in the property table
SELECT * FROM real_estate.property WHERE property_id = 1;


/*5. 2 Create a function that adds a new transaction to your transaction table. 
You can define the input arguments and output format. 
Make sure all transaction attributes can be set with the function (via their natural keys). 
The function does not need to return a value but should confirm the successful insertion of the new transaction.*/

CREATE OR REPLACE FUNCTION add_transaction(
    p_client_name TEXT,
    p_property_address TEXT,
    p_date DATE,
    p_amount NUMERIC
)
RETURNS VOID AS $$
DECLARE
    v_client_id INT;
    v_property_id INT;
BEGIN
    -- Retrieve client_id based on client_name
    SELECT client_id INTO v_client_id
    FROM real_estate.client
    WHERE client_name = p_client_name;
    -- Retrieve property_id based on property_address
    SELECT property_id INTO v_property_id
    FROM real_estate.property
    WHERE address = p_property_address;
    -- Raise notice for debugging
    RAISE NOTICE 'Client ID: %, Property ID: %, Amount: %, Date: %',
        v_client_id, v_property_id, p_amount, p_date;
    -- Insert new transaction
    INSERT INTO real_estate."transaction" (client_id, property_id, date, amount)
    VALUES (v_client_id, v_property_id, p_date, p_amount);
    RAISE NOTICE 'Transaction successfully added for client %, property %', p_client_name, p_property_address;
END;
$$ LANGUAGE plpgsql;

-- TEST :Add a new transaction for a client and property
SELECT add_transaction(
    'Alice Johnson',          -- Client name
    '123 Elm Street',         -- Property address
    '2024-09-15',             -- Transaction date
    250000                    -- Transaction amount
);

-- Verifying:
-- Verify the transaction was added
SELECT client_id, property_id, date, amount
FROM real_estate."transaction"
WHERE client_id = (SELECT client_id FROM real_estate.client WHERE client_name = 'Alice Johnson')
  AND property_id = (SELECT property_id FROM real_estate.property WHERE address = '123 Elm Street')
  AND date = '2024-09-15'
  AND amount = 250000;


--6. Create a view that presents analytics for the most recently added quarter in your database. Ensure that the result excludes irrelevant fields such as surrogate keys and duplicate entries.

CREATE OR REPLACE VIEW real_estate.analytics_recent_quarter AS
WITH recent_quarter AS (
    SELECT
        EXTRACT(YEAR FROM t.date) AS year,
        EXTRACT(QUARTER FROM t.date) AS quarter
    FROM real_estate."transaction" t
    ORDER BY t.date DESC
    LIMIT 1
)
SELECT
    c.client_name,
    p.address AS property_address,
    t.date AS transaction_date,
    t.amount AS transaction_amount
FROM
    real_estate."transaction" t
JOIN real_estate.client c ON t.client_id = c.client_id
JOIN real_estate.property p ON t.property_id = p.property_id
WHERE
    EXTRACT(YEAR FROM t.date) = (SELECT year FROM recent_quarter)
    AND EXTRACT(QUARTER FROM t.date) = (SELECT quarter FROM recent_quarter);

   
-- TEST : Query the view
SELECT * FROM real_estate.analytics_recent_quarter;



/*7. Create a read-only role for the manager. This role should have permission to perform SELECT queries on the database tables, and also be able to log in. 
Please ensure that you adhere to best practices for database security when defining this role*/
DO $$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM pg_roles WHERE rolname='manager') THEN
        CREATE ROLE manager
		WITH LOGIN PASSWORD 'secure_password';
    END IF;
END
$$ LANGUAGE plpgsql;

--Grant SELECT privileges on all existing tables in the real_estate schema
GRANT SELECT ON ALL TABLES IN SCHEMA real_estate TO manager;

--Ensure the manager can access future tables in the real_estate schema
ALTER DEFAULT PRIVILEGES IN SCHEMA real_estate
    GRANT SELECT ON TABLES TO manager;

--Revoke INSERT, UPDATE, DELETE permissions if they were granted before
REVOKE INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA real_estate FROM manager;

--Ensure the manager can use the schema but not create new objects
GRANT USAGE ON SCHEMA real_estate TO manager;

--Verify role permissions and existence
SELECT rolname, rolsuper, rolinherit, rolcreaterole, rolcreatedb FROM pg_roles WHERE rolname = 'manager';


--TEST: Log in as the manager and attempt to query a table
SET ROLE manager;
SELECT * FROM real_estate.client;
