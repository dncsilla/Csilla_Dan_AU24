/*
 1.Create a physical database with a separate database and schema and give it an appropriate domain-related name. 
 Use the relational model you've created while studying DB Basics module. Task 2 (designing a logical data model on the chosen topic). 
 Make sure you have made any changes to your model after your mentor's comments.
 2.Your database must be in 3NF
 3.Use appropriate data types for each column and apply DEFAULT values, and GENERATED ALWAYS AS columns as required.
 4.Create relationships between tables using primary and foreign keys.
 5.Apply five check constraints across the tables to restrict certain values, including
  -date to be inserted, which must be greater than January 1, 2000
  -inserted measured value that cannot be negative
  -inserted value that can only be a specific value (as an example of gender)
  -unique
  -not null

 6.Populate the tables with the sample data generated, ensuring each table has at least two rows (for a total of 20+ rows in all the tables).
 7.Add a not null 'record_ts' field to each table using ALTER TABLE statements, set the default value to current_date, and check to make sure the value has
 been set for the existing rows.

Note:
Your physical model should be in 3nf, all constraints, data types correspond your logical model
Your code must be reusable and rerunnable and executes without errors
Your code should not produces duplicates
Avoid hardcoding
Use appropriate data types
Add comments (as example why you chose particular constraint, datatytpe, etc.)
Please attached a graphical image with your fixed logical model */

--1. Creating the database
DROP  DATABASE recruitment_agency; 
--2.Creating SCHEMA for DATABASE
CREATE SCHEMA recruitment;
--Creating the tables starting with the less complex ones:
-- Table: Status
CREATE TABLE IF NOT EXISTS recruitment.Status (
    StatusID INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,  -- Unique identifier for each status
    StatusName VARCHAR(50) UNIQUE NOT NULL  -- Descriptive status name, can NOT be NULL value
    CONSTRAINT chk_status_name CHECK (StatusName IN ('Active', 'Pending', 'Interviewing', 'Closed')) --Adding CHECK CONSTRAINT for inserted value that can only be a specific value
);
-- Table: JobType
CREATE TABLE IF NOT EXISTS recruitment.JobType (
    JobTypeID INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,  -- Unique identifier for job types
    JobTypeName VARCHAR(50) UNIQUE NOT NULL  -- Descriptive name of job TYPE,can NOT be NULL value
);
-- Table: Recruiters
CREATE TABLE IF NOT EXISTS recruitment.Recruiters (
    RecruiterID INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,  -- Unique identifier for recruiters
    FirstName VARCHAR(50) NOT NULL,  -- First name of the recruiter, can NOT be NULL value
    LastName VARCHAR(50) NOT NULL,  -- Last name of the recruiter, can NOT be NULL value
    Email VARCHAR(100) UNIQUE NOT NULL,  -- Unique email for communication, can NOT be NULL value
    PhoneNumber VARCHAR(15)  -- Contact number
);
-- Table: Companies
CREATE TABLE IF NOT EXISTS recruitment.Companies (
    CompanyID INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,  -- Unique ID for each company
    CompanyName VARCHAR(100) UNIQUE NOT NULL,  -- Company name, unique for identification
    ContactEmail VARCHAR(100),  -- Contact email for communication, not necessarily unique
    ContactPerson VARCHAR(100),  -- Name of the contact person
    ContactPhone VARCHAR(15)  -- Phone number of the contact person
);
-- Table: Candidates
CREATE TABLE IF NOT EXISTS recruitment.Candidates (
    CandidateID INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,  -- Auto-incrementing ID for unique candidate identification
    FirstName VARCHAR(50) NOT NULL,  -- First name, VARCHAR chosen for variable length
    LastName VARCHAR(50) NOT NULL,   -- Last name, VARCHAR chosen for variable length
    Email VARCHAR(100) UNIQUE NOT NULL,  -- Email must be unique to avoid duplicates
    PhoneNumber VARCHAR(15),  -- Phone numbers can vary in length, hence VARCHAR(15)
    DateOfBirth DATE CHECK (DateOfBirth > '1900-01-01'),  -- Ensures valid date of birth
    StatusID INTEGER,  -- Foreign key reference to Status table, uses INTEGER for compatibility
    Resume TEXT,  -- Large text field for storing resume content
    FOREIGN KEY (StatusID) REFERENCES recruitment.Status(StatusID)  -- Ensures referential integrity
);
-- Table: Location
CREATE TABLE IF NOT EXISTS recruitment.Location (
    LocationID INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,  -- Unique identifier for locations
    City VARCHAR(50),  -- City name
    State VARCHAR(50),  -- State name
    Country VARCHAR(50) NOT NULL  -- Country name, mandatory, can NOT be NULL value
);
-- Table: Jobs
CREATE TABLE IF NOT EXISTS recruitment.Jobs (
    JobID INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,  -- Unique identifier for each job, Auto-incrementing
    JobTitle VARCHAR(100) NOT NULL,  -- Job title, variable length up to 100 chars, can NOT be NULL value
    Description TEXT,  -- Detailed job description, uses TEXT for large input
    JobTypeID INTEGER,  -- References JobType table
    LocationID INTEGER,  -- References Location table
    StatusID INTEGER,  -- References Status table
    DatePosted DATE NOT NULL CHECK (DatePosted > '2000-01-01'),  -- Date validation
    FOREIGN KEY (JobTypeID) REFERENCES recruitment.JobType(JobTypeID),
    FOREIGN KEY (LocationID) REFERENCES recruitment.Location(LocationID),
    FOREIGN KEY (StatusID) REFERENCES recruitment.Status(StatusID)
);
-- Table: Applications
CREATE TABLE IF NOT EXISTS recruitment.Applications (
    ApplicationID INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,  -- Unique ID for each application
    CandidateID INTEGER NOT NULL,  -- References Candidates table
    JobID INTEGER NOT NULL,  -- References Jobs table
    ApplicationDate DATE NOT NULL CHECK (ApplicationDate > '2000-01-01'),  -- Ensures valid date, can NOT be NULL value
    StatusID INTEGER,  -- References Status table
    FOREIGN KEY (CandidateID) REFERENCES recruitment.Candidates(CandidateID),
    FOREIGN KEY (JobID) REFERENCES recruitment.Jobs(JobID),
    FOREIGN KEY (StatusID) REFERENCES recruitment.Status(StatusID),
    CONSTRAINT chk_applications_date CHECK (ApplicationDate <= CURRENT_DATE)
);
-- Table: Interviews
CREATE TABLE IF NOT EXISTS recruitment.Interviews (
    InterviewID INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,  -- Unique identifier for interviews
    CandidateID INTEGER NOT NULL,  -- References Candidates TABLE, can NOT be NULL value
    JobID INTEGER NOT NULL,  -- References Jobs TABLE, can NOT be NULL value
    InterviewDate DATE NOT NULL CHECK (InterviewDate > '2000-01-01'),  -- Valid interview date
    Feedback TEXT,  -- Feedback on the interview
    FOREIGN KEY (CandidateID) REFERENCES recruitment.Candidates(CandidateID),
    FOREIGN KEY (JobID) REFERENCES recruitment.Jobs(JobID)
);
-- Table: Company_Locations
CREATE TABLE IF NOT EXISTS recruitment.Company_Locations (
    CompanyID INTEGER NOT NULL,  -- can NOT be NULL value
    LocationID INTEGER NOT NULL,  -- can NOT be NULL value
    PRIMARY KEY (CompanyID, LocationID),  -- Composite primary KEY, 
    FOREIGN KEY (CompanyID) REFERENCES recruitment.Companies(CompanyID), --References Companies table
    FOREIGN KEY (LocationID) REFERENCES recruitment.Location(LocationID) --References Location table
);
-- Table: Work_with
CREATE TABLE IF NOT EXISTS recruitment.Work_with (
    CompanyID INTEGER NOT NULL,  -- can NOT be NULL value
    RecruiterID INTEGER NOT NULL,  -- can NOT be NULL value
    Start_date DATE NOT NULL CHECK (Start_date > '2000-01-01'),  -- Valid start date
    End_date DATE,  -- Optional end date
    Contract_type VARCHAR(50) NOT NULL,  -- Type of contract
    Contact_terms TEXT,  -- Detailed contract terms
    PRIMARY KEY (CompanyID, RecruiterID),  -- Composite primary KEY, 
    FOREIGN KEY (CompanyID) REFERENCES recruitment.Companies(CompanyID), --References Companies TABLE
    FOREIGN KEY (RecruiterID) REFERENCES recruitment.Recruiters(RecruiterID) --References Recruiters table
);
-- Table: Skills
CREATE TABLE IF NOT EXISTS recruitment.Skills (
    SkillID INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,  -- Auto-incrementing unique identifier for each skill
    SkillName VARCHAR(100) UNIQUE NOT NULL  -- Skill name, must be unique to prevent duplicates, can NOT be NULL value
);
-- Table: JobSkills
CREATE TABLE IF NOT EXISTS recruitment.JobSkills (
    JobSkillID INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,  -- Unique ID for each job-skill mapping
    JobID INTEGER NOT NULL,  -- References Jobs TABLE, can NOT be NULL value
    SkillID INTEGER NOT NULL,  -- References Skills TABLE,  can NOT be NULL value
    FOREIGN KEY (JobID) REFERENCES recruitment.Jobs(JobID),
    FOREIGN KEY (SkillID) REFERENCES recruitment.Skills(SkillID)
);
-- Table: CandidateSkills
CREATE TABLE IF NOT EXISTS recruitment.CandidateSkills (
    CandidateSkillID INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,  -- Unique ID for each candidate-skill mapping
    CandidateID INTEGER NOT NULL,  -- References Candidates TABLE, can NOT be NULL value
    SkillID INTEGER NOT NULL,  -- References Skills TABLE, can NOT be NULL value
    FOREIGN KEY (CandidateID) REFERENCES recruitment.Candidates(CandidateID),
    FOREIGN KEY (SkillID) REFERENCES recruitment.Skills(SkillID)
);
-- Altering all tables to have record_ts column with current date as default
ALTER TABLE recruitment.Skills
    ADD COLUMN record_ts DATE NOT NULL DEFAULT CURRENT_DATE;
ALTER TABLE recruitment.JobSkills
    ADD COLUMN record_ts DATE NOT NULL DEFAULT CURRENT_DATE;
ALTER TABLE recruitment.Candidates
    ADD COLUMN record_ts DATE NOT NULL DEFAULT CURRENT_DATE;
ALTER TABLE recruitment.Status
    ADD COLUMN record_ts DATE NOT NULL DEFAULT CURRENT_DATE;
ALTER TABLE recruitment.CandidateSkills
    ADD COLUMN record_ts DATE NOT NULL DEFAULT CURRENT_DATE;
ALTER TABLE recruitment.Applications
    ADD COLUMN record_ts DATE NOT NULL DEFAULT CURRENT_DATE;
ALTER TABLE recruitment.Jobs
    ADD COLUMN record_ts DATE NOT NULL DEFAULT CURRENT_DATE;
ALTER TABLE recruitment.JobType
    ADD COLUMN record_ts DATE NOT NULL DEFAULT CURRENT_DATE;
ALTER TABLE recruitment.Location
    ADD COLUMN record_ts DATE NOT NULL DEFAULT CURRENT_DATE;
ALTER TABLE recruitment.Interviews
    ADD COLUMN record_ts DATE NOT NULL DEFAULT CURRENT_DATE;
ALTER TABLE recruitment.Recruiters
    ADD COLUMN record_ts DATE NOT NULL DEFAULT CURRENT_DATE;
ALTER TABLE recruitment.Companies
    ADD COLUMN record_ts DATE NOT NULL DEFAULT CURRENT_DATE;
ALTER TABLE recruitment.Company_Locations
    ADD COLUMN record_ts DATE NOT NULL DEFAULT CURRENT_DATE;
ALTER TABLE recruitment.Work_with
    ADD COLUMN record_ts DATE NOT NULL DEFAULT CURRENT_DATE;
-- Creating a CHECK to to make sure the value has been set for the existing rows.
WITH check_nulls AS (
    SELECT 'Status' AS table_name, COUNT(*) AS null_count 
    FROM recruitment.Status WHERE record_ts IS NULL
    UNION ALL
    SELECT 'JobType', COUNT(*) FROM recruitment.JobType WHERE record_ts IS NULL
    UNION ALL
    SELECT 'Recruiters', COUNT(*) FROM recruitment.Recruiters WHERE record_ts IS NULL
    UNION ALL
    SELECT 'Location', COUNT(*) FROM recruitment.Location WHERE record_ts IS NULL
    UNION ALL
    SELECT 'Companies', COUNT(*) FROM recruitment.Companies WHERE record_ts IS NULL
    UNION ALL
    SELECT 'Candidates', COUNT(*) FROM recruitment.Candidates WHERE record_ts IS NULL
    UNION ALL
    SELECT 'Jobs', COUNT(*) FROM recruitment.Jobs WHERE record_ts IS NULL
    UNION ALL
    SELECT 'Applications', COUNT(*) FROM recruitment.Applications WHERE record_ts IS NULL
    UNION ALL 
    SELECT 'Work_with', COUNT(*) FROM recruitment.Work_with WHERE record_ts IS NULL
    UNION ALL 
    SELECT 'Company_Locations',COUNT(*) FROM recruitment.Company_Locations WHERE record_ts IS NULL
    UNION ALL 
    SELECT 'Interviews', COUNT (*) FROM recruitment.Interviews WHERE record_ts IS NULL
    UNION ALL 
    SELECT 'Skills', COUNT(*) FROM recruitment.Skills WHERE record_ts IS NULL
    UNION ALL 
    SELECT 'Jobskills', COUNT(*) FROM recruitment.JobSkills WHERE record_ts IS NULL
    UNION ALL 
    SELECT 'CandidateSkills', COUNT(*) FROM recruitment.CandidateSkills WHERE record_ts IS NULL
)
SELECT * FROM check_nulls WHERE null_count > 0;
-- INSERTING DATA
WITH 
    -- 1. Insert into Status table
    inserted_status AS (
        INSERT INTO recruitment.Status (StatusName)
        SELECT StatusName
        FROM (
            SELECT 'Active' AS StatusName
            UNION ALL
            SELECT 'Pending'
            UNION ALL
            SELECT 'Interviewing'
        ) AS status_list
        WHERE NOT EXISTS (
            SELECT statusid FROM recruitment.Status s WHERE s.StatusName = status_list.StatusName
        )
        RETURNING StatusID, StatusName
    ),
    -- 2. Insert into JobType table
    inserted_jobtype AS (
        INSERT INTO recruitment.JobType (JobTypeName)
        SELECT JobTypeName
        FROM (
            SELECT 'Full-time' AS JobTypeName
            UNION ALL
            SELECT 'Part-time'
            UNION ALL
            SELECT 'Contract'
        ) AS jobtype_list
        WHERE NOT EXISTS (
            SELECT JobTypeID FROM recruitment.JobType jt WHERE jt.JobTypeName = jobtype_list.JobTypeName
        )
        RETURNING JobTypeID, JobTypeName
    ),
    -- 3. Insert into Recruiters table
    inserted_recruiters AS (
        INSERT INTO recruitment.Recruiters (FirstName, LastName, Email, PhoneNumber)
        SELECT FirstName, LastName, Email, PhoneNumber
        FROM (
            SELECT 'Mark', 'Doe', 'mark.doe@example.com', '1234567890'
            UNION ALL
            SELECT 'Alice', 'Johnson', 'alice@techcorp.com', '555-3333'
        ) AS recruiters_list (FirstName, LastName, Email, PhoneNumber)
        WHERE NOT EXISTS (
            SELECT RecruiterID FROM recruitment.Recruiters r WHERE r.Email = recruiters_list.Email
        )
        RETURNING RecruiterID, FirstName, LastName, Email
    ),
    -- 4. Insert into Location table
    inserted_location AS (
        INSERT INTO recruitment.Location (City, State, Country)
        SELECT City, State, Country
        FROM (
            SELECT 'New York', 'NY', 'USA'
            UNION ALL
            SELECT 'San Francisco', 'CA', 'USA'
        ) AS location_list (City, State, Country)
        WHERE NOT EXISTS (
            SELECT LocationID FROM recruitment.Location l 
            WHERE l.City = location_list.City AND l.State = location_list.State AND l.Country = location_list.Country
        )
        RETURNING LocationID, City, State, Country
    ),
    -- 5. Insert into Companies table
    inserted_companies AS (
        INSERT INTO recruitment.Companies (CompanyName, ContactEmail, ContactPerson, ContactPhone)
        SELECT CompanyName, ContactEmail, ContactPerson, ContactPhone
        FROM (
            SELECT 'Tech Solutions Inc.', 'contact@techsolutions.com', 'Anne White', '9876543210'
            UNION ALL
            SELECT 'Tech Corp', 'info@techcorp.com', 'Jane Smith', '555-1111'
        ) AS companies_list (CompanyName, ContactEmail, ContactPerson, ContactPhone)
        WHERE NOT EXISTS (
            SELECT CompanyID FROM recruitment.Companies c WHERE c.CompanyName = companies_list.CompanyName
        )
        RETURNING CompanyID, CompanyName, ContactEmail, ContactPerson
    ),
    -- 6. Insert into Candidates table
    inserted_candidates AS (
        INSERT INTO recruitment.Candidates (FirstName, LastName, Email, PhoneNumber, DateOfBirth, StatusID, Resume)
        SELECT 
            'John', 'Doe', 'john.doe@email.com', '123-456-7890', '1990-01-01'::date,
            (SELECT StatusID FROM recruitment.Status WHERE StatusName = 'Active'), 
            'john_resume.pdf'
        WHERE NOT EXISTS (
            SELECT CandidateID FROM recruitment.Candidates c WHERE c.Email = 'john.doe@email.com'
        )
        UNION ALL
        SELECT 
            'Bob', 'Williams', 'bob.williams@example.com', '4561237890', '1985-10-15'::date,
            (SELECT StatusID FROM recruitment.Status WHERE StatusName = 'Pending'), 
            'Resume content here...'
        WHERE NOT EXISTS (
            SELECT CandidateID FROM recruitment.Candidates c WHERE c.Email = 'bob.williams@example.com'
        )
        RETURNING CandidateID, FirstName, LastName, Email
    ),
    -- 7. Insert into Jobs table
    inserted_jobs AS (
        INSERT INTO recruitment.Jobs (JobTitle, Description, JobTypeID, LocationID, StatusID, DatePosted)
        SELECT 
            'Software Engineer', 'Develop and maintain software applications',
            (SELECT JobTypeID FROM recruitment.JobType WHERE JobTypeName = 'Full-time'),
            (SELECT LocationID FROM recruitment.Location WHERE City = 'New York'),
            (SELECT StatusID FROM recruitment.Status WHERE StatusName = 'Active'),
            CURRENT_DATE
        WHERE NOT EXISTS (
            SELECT j.JobID FROM recruitment.Jobs j WHERE j.JobTitle = 'Software Engineer'
        )
        UNION ALL
        SELECT 
            'Project Manager', 'Manage projects and ensure timely delivery',
            (SELECT JobTypeID FROM recruitment.JobType WHERE JobTypeName = 'Contract'),
            (SELECT LocationID FROM recruitment.Location WHERE City = 'San Francisco'),
            (SELECT StatusID FROM recruitment.Status WHERE StatusName = 'Pending'),
            CURRENT_DATE
        WHERE NOT EXISTS (
            SELECT j.JobID FROM recruitment.Jobs j WHERE j.JobTitle = 'Project Manager'
        )
        RETURNING JobID, JobTitle, Description
    )
    SELECT * FROM inserted_jobs;
    -- 8. Insert into Applications table
 WITH  inserted_applications AS (
        INSERT INTO recruitment.Applications (CandidateID, JobID, ApplicationDate, StatusID)
        SELECT 
            (SELECT c.CandidateID FROM recruitment.Candidates c WHERE UPPER(c.firstname)= UPPER('John') AND UPPER(c.lastname) = UPPER('Doe')),
            (SELECT JobID FROM recruitment.Jobs WHERE JobTitle = 'Software Engineer'),
            CURRENT_DATE,
            (SELECT StatusID FROM recruitment.Status WHERE StatusName = 'Interviewing')
        WHERE NOT EXISTS (
            SELECT ApplicationID FROM recruitment.Applications a 
            WHERE a.CandidateID = (SELECT CandidateID FROM recruitment.Candidates c WHERE UPPER(c.firstname)= UPPER('John') AND UPPER(c.lastname) = UPPER('Doe'))
            AND a.JobID = (SELECT JobID FROM recruitment.Jobs WHERE JobTitle = 'Software Engineer')
        )
        UNION ALL
        SELECT 
            (SELECT c.CandidateID FROM recruitment.Candidates c WHERE Email = 'bob.williams@example.com'),
            (SELECT JobID FROM recruitment.Jobs WHERE JobTitle = 'Project Manager'),
            CURRENT_DATE,
            (SELECT StatusID FROM recruitment.Status WHERE StatusName = 'Pending')
        WHERE NOT EXISTS (
            SELECT ApplicationID FROM recruitment.Applications a 
            WHERE a.CandidateID = (SELECT CandidateID FROM recruitment.Candidates WHERE UPPER(Email) = UPPER('bob.williams@example.com'))
            AND a.JobID = (SELECT JobID FROM recruitment.Jobs WHERE JobTitle = 'Project Manager')
        )
        RETURNING ApplicationID, CandidateID, JobID, ApplicationDate
    )
-- View the inserted applications
SELECT * FROM inserted_applications;
-- 9. Insert into Interviews table
WITH inserted_interviews AS (
    INSERT INTO recruitment.Interviews (CandidateID, JobID, InterviewDate, Feedback)
    SELECT 
        (SELECT CandidateID FROM recruitment.Candidates WHERE Email = 'john.doe@email.com'),
        (SELECT JobID FROM recruitment.Jobs WHERE JobTitle = 'Software Engineer'),
        CURRENT_DATE + INTERVAL '7 days', --automaticly setting the interview date 7 days away FROM the CURRENT date
        'Great potential, needs more experience.'
    WHERE NOT EXISTS (
        SELECT InterviewID FROM recruitment.Interviews i 
        WHERE i.CandidateID = (SELECT CandidateID FROM recruitment.Candidates WHERE Email = 'john.doe@email.com')
        AND i.JobID = (SELECT JobID FROM recruitment.Jobs WHERE JobTitle = 'Software Engineer')
    )
    UNION ALL
    SELECT 
        (SELECT CandidateID FROM recruitment.Candidates WHERE Email = 'bob.williams@example.com'),
        (SELECT JobID FROM recruitment.Jobs WHERE JobTitle = 'Project Manager'),
        CURRENT_DATE + INTERVAL '10 days', --automaticly setting the interview date 7 days away FROM the CURRENT date
        'Good communication skills.'
    WHERE NOT EXISTS (
        SELECT InterviewID FROM recruitment.Interviews i 
        WHERE i.CandidateID = (SELECT CandidateID FROM recruitment.Candidates WHERE Email = 'bob.williams@example.com')
        AND i.JobID = (SELECT JobID FROM recruitment.Jobs WHERE JobTitle = 'Project Manager')
    )
    RETURNING InterviewID, CandidateID, JobID, InterviewDate, Feedback
)
SELECT * FROM inserted_interviews;
-- 10. Insert into Company_Locations table
WITH inserted_company_locations AS (
    INSERT INTO recruitment.Company_Locations (CompanyID, LocationID)
    SELECT 
        (SELECT CompanyID FROM recruitment.Companies WHERE CompanyName = 'Tech Solutions Inc.'),
        (SELECT LocationID FROM recruitment.Location WHERE City = 'New York')
    WHERE NOT EXISTS (
        SELECT * FROM recruitment.Company_Locations 
        WHERE CompanyID = (SELECT CompanyID FROM recruitment.Companies WHERE CompanyName = 'Tech Solutions Inc.')
        AND LocationID = (SELECT LocationID FROM recruitment.Location WHERE City = 'New York')
    )
    UNION ALL
    SELECT 
        (SELECT CompanyID FROM recruitment.Companies WHERE CompanyName = 'Tech Corp'),
        (SELECT LocationID FROM recruitment.Location WHERE City = 'San Francisco')
    WHERE NOT EXISTS (
        SELECT * FROM recruitment.Company_Locations 
        WHERE CompanyID = (SELECT CompanyID FROM recruitment.Companies WHERE CompanyName = 'Tech Corp')
        AND LocationID = (SELECT LocationID FROM recruitment.Location WHERE City = 'San Francisco')
    )
    RETURNING CompanyID, LocationID
)
SELECT * FROM inserted_company_locations;
-- 11. Insert into Work_with table
WITH inserted_work_with AS (
    INSERT INTO recruitment.Work_with (CompanyID, RecruiterID, Start_date, Contract_type, Contact_terms)
    SELECT 
        (SELECT CompanyID FROM recruitment.Companies WHERE CompanyName = 'Tech Solutions Inc.'),
        (SELECT RecruiterID FROM recruitment.Recruiters WHERE Email = 'mark.doe@example.com'),
        CURRENT_DATE, 'Full-time', 'Standard Contract Terms'
    WHERE NOT EXISTS (
        SELECT * FROM recruitment.Work_with 
        WHERE CompanyID = (SELECT CompanyID FROM recruitment.Companies WHERE CompanyName = 'Tech Solutions Inc.')
        AND RecruiterID = (SELECT RecruiterID FROM recruitment.Recruiters WHERE Email = 'mark.doe@example.com')
    )
    UNION ALL
    SELECT 
        (SELECT CompanyID FROM recruitment.Companies WHERE CompanyName = 'Tech Corp'),
        (SELECT RecruiterID FROM recruitment.Recruiters WHERE Email = 'alice@techcorp.com'),
        CURRENT_DATE, 'Part-time', 'Flexible Contract Terms'
    WHERE NOT EXISTS (
        SELECT * FROM recruitment.Work_with 
        WHERE CompanyID = (SELECT CompanyID FROM recruitment.Companies WHERE CompanyName = 'Tech Corp')
        AND RecruiterID = (SELECT RecruiterID FROM recruitment.Recruiters WHERE Email = 'alice@techcorp.com')
    )
    RETURNING CompanyID, RecruiterID, Start_date
)
SELECT * FROM inserted_work_with;
-- 12. Insert into Skills table
WITH inserted_skills AS (
    INSERT INTO recruitment.Skills (SkillName)
    SELECT SkillName
    FROM (
        SELECT 'Python' AS SkillName
        UNION ALL
        SELECT 'Project Management'
    ) AS skill_list
    WHERE NOT EXISTS (
        SELECT SkillID FROM recruitment.Skills s WHERE s.SkillName = skill_list.SkillName
    )
    RETURNING SkillID, SkillName
)
SELECT * FROM inserted_skills;
-- 13.Insert into JobSkills table
WITH inserted_jobskills AS (
    INSERT INTO recruitment.JobSkills (JobID, SkillID)
    SELECT 
        (SELECT JobID FROM recruitment.Jobs WHERE JobTitle = 'Software Engineer'),
        (SELECT SkillID FROM recruitment.Skills WHERE SkillName = 'Python')
    WHERE NOT EXISTS (
        SELECT * FROM recruitment.JobSkills 
        WHERE JobID = (SELECT JobID FROM recruitment.Jobs WHERE JobTitle = 'Software Engineer')
        AND SkillID = (SELECT SkillID FROM recruitment.Skills WHERE SkillName = 'Python')
    )
    UNION ALL
    SELECT 
        (SELECT JobID FROM recruitment.Jobs WHERE JobTitle = 'Project Manager'),
        (SELECT SkillID FROM recruitment.Skills WHERE SkillName = 'Project Management')
    WHERE NOT EXISTS (
        SELECT * FROM recruitment.JobSkills 
        WHERE JobID = (SELECT JobID FROM recruitment.Jobs WHERE JobTitle = 'Project Manager')
        AND SkillID = (SELECT SkillID FROM recruitment.Skills WHERE SkillName = 'Project Management')
    )
    RETURNING JobSkillID, JobID, SkillID
)
SELECT * FROM inserted_jobskills;
-- 14. Insert into CandidateSkills table
WITH inserted_candidateskills AS (
    INSERT INTO recruitment.CandidateSkills (CandidateID, SkillID)
    SELECT 
        (SELECT CandidateID FROM recruitment.Candidates WHERE Email = 'john.doe@email.com'),
        (SELECT SkillID FROM recruitment.Skills WHERE SkillName = 'Python')
    WHERE NOT EXISTS (
        SELECT * FROM recruitment.CandidateSkills 
        WHERE CandidateID = (SELECT CandidateID FROM recruitment.Candidates WHERE Email = 'john.doe@email.com')
        AND SkillID = (SELECT SkillID FROM recruitment.Skills WHERE SkillName = 'Python')
    )
    UNION ALL
    SELECT 
        (SELECT CandidateID FROM recruitment.Candidates WHERE Email = 'bob.williams@example.com'),
        (SELECT SkillID FROM recruitment.Skills WHERE SkillName = 'Project Management')
    WHERE NOT EXISTS (
        SELECT * FROM recruitment.CandidateSkills 
        WHERE CandidateID = (SELECT CandidateID FROM recruitment.Candidates WHERE Email = 'bob.williams@example.com')
        AND SkillID = (SELECT SkillID FROM recruitment.Skills WHERE SkillName = 'Project Management')
    )
    RETURNING CandidateSkillID, CandidateID, SkillID
)
SELECT * FROM inserted_candidateskills;


