--0.Database origin

--https://www.superdatascience.com/pages/sql
--https://sds-platform-private.s3-us-east-2.amazonaws.com/uploads/P9-Section7-The-Challenge.pdf

--1. Login to the system pgAdmin / PostgreSQL

--pgAdmin
        --username = "XXXX"
		--passwd = "XXXX"
		--hostname = "127.0.0.1" // "localhost"
		--db_name = "random name"

--2. Create database, tabels and convert data from .csv files

CREATE DATABASE "VETERINARY"
  WITH OWNER = postgres
       ENCODING = 'UTF8'
       TABLESPACE = pg_default
       LC_COLLATE = 'pl_PL.UTF-8'
       LC_CTYPE = 'pl_PL.UTF-8'
       CONNECTION LIMIT = -1
       ;

CREATE TABLE pets (
    pet_id varchar(8) UNIQUE,
    name varchar(50) NOT NULL,
    kind varchar(8) NOT NULL,
    gender varchar(8) NOT NULL,
    age int,
    ownerid varchar
);

COPY pets FROM '/home/monika/Pulpit/SQL projeky/bazalosl/P9-Pets.csv' DELIMITER ',' CSV HEADER;

CREATE TABLE owners (
    ownerid varchar(8) NOT NULL UNIQUE,
    name varchar(16) NOT NULL,
    surname varchar(16) NOT NULL,
    streetaddress varchar(32) NOT NULL,
    city varchar(32) NOT NULL,
    state varchar(8) DEFAULT 'Michigan',
    statefull varchar,
    zipcode varchar
);

COPY owners FROM '/home/monika/Pulpit/SQL projeky/bazalosl/P9-Owners.csv' DELIMITER ',' CSV HEADER;

CREATE TABLE procedure (
    procedureid int NOT NULL UNIQUE,
    proceduretype varchar(32),
    proceduresubcode varchar(32),
    description varchar(32),
    price int
);

COPY procedure FROM '/home/monika/Pulpit/SQL projeky/bazalosl/P9-ProceduresDetails.csv' DELIMITER ',' CSV HEADER;

CREATE TABLE history (
    petid varchar(8),
    proceduredate date,
    proceduretype varchar(32),
    proceduresubcode varchar(8)
);

COPY history FROM '/home/monika/Pulpit/SQL projeky/bazalosl/P9-ProceduresHistory.csv' DELIMITER ',' CSV HEADER;

CREATE TYPE address AS (
	streetaddress varchar(32),
	city varchar(16),
	state varchar(16),
	statefull varchar(32),
	zipcode varchar
);

CREATE TYPE full_name AS (
	first_name varchar(16),
	midname varchar(16),
	surname varchar(32)
);

CREATE TYPE specialisation AS (
       kind_animal varchar(16),
       surgery varchar(8),
       beauty_grooming varchar (16)
);

CREATE TABLE vets (
    vet_id SERIAL PRIMARY KEY,
	name full_name,
	address	address,
	vet_specialisation specialisation,
	salary_fixed numeric(4,0),
    overhours_rate numeric(3,0),
	overhours integer
);

--3. Prepare and populate data in tables

--PETS table

ALTER TABLE pets
ADD PRIMARY KEY (pet_id);

CREATE UNIQUE INDEX idx_pets_petid
ON pets(pet_id);

-- check if pet id can be pk?:: yes
SELECT pet_id as "unique pet id",
COUNT(*)::int as "number of idks"
FROM pets
GROUP BY pet_id;

ALTER TABLE pets
RENAME ownerid TO owner_id;

-- check if owner id can not be pk? ::no
SELECT owner_id as "unique owner id",
COUNT(*)::int as "number of owneridks"
FROM pets
GROUP BY owner_id;

ALTER TABLE pets
ADD COLUMN sign_up date;

-- added some fake dates in 'sign up' in pets
CREATE OR REPLACE FUNCTION random_date_in_range(DATE, DATE)
RETURNS DATE
LANGUAGE SQL
AS $$
    SELECT $1 + floor( ($2 - $1 + 1) * random() )::INTEGER;
$$;

UPDATE pets SET sign_up = random_date_in_range('2012-01-01', '2016-01-01');

ALTER TABLE pets
ALTER COLUMN sign_up SET DEFAULT now()::abstime;

CREATE OR REPLACE FUNCTION pets_timestamp() RETURNS trigger AS $$
BEGIN
    NEW.sign_up := now()::date;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS pets_timestamp ON pets;

SELECT version();

CREATE TRIGGER pets_timestamp BEFORE INSERT ON pets
FOR EACH ROW EXECUTE PROCEDURE pets_timestamp();

--change data to more readable and intuitive
UPDATE   pets
SET      gender = REPLACE(gender, 'male', 'M')
WHERE    gender LIKE 'm%';

UPDATE   pets
SET      gender = REPLACE(gender, 'female', 'F')
WHERE    gender LIKE 'f%';

ALTER TABLE pets
ADD CONSTRAINT age CHECK (age >= 0 AND age <= 19);

SELECT MAX(pet_id) FROM pets;

ALTER TABLE pets ALTER COLUMN pet_id TYPE integer USING (trim(pet_id)::integer);

CREATE SEQUENCE IF NOT EXISTS pets_petid_seq
INCREMENT by 1
START WITH 101 OWNED BY pets.pet_id;

SELECT nextval('pets_petid_seq');

INSERT INTO pets (pet_id, name, kind, gender, age, owner_id, sign_up)
VALUES (nextval('pets_petid_seq'),'Koko','Dog','K',5,'5168', DEFAULT);

--OWNERS table

ALTER TABLE owners
RENAME ownerid TO owner_id;

-- owner id can be pk?::yes
SELECT owner_id as "unique owner id",
COUNT(*)::int as "number of owners"
FROM owners
GROUP BY owner_id;

ALTER TABLE owners
ADD PRIMARY KEY (owner_id);

ALTER TABLE pets
ADD CONSTRAINT pets_customerid_fkey
FOREIGN KEY (owner_id) REFERENCES owners(owner_id)
ON UPDATE CASCADE
ON DELETE CASCADE;

ALTER TABLE owners
ALTER COLUMN State SET DEFAULT 'MI';

UPDATE owners
SET StateFull = 'Michigan'
WHERE State is null or State = 'MI';

ALTER TABLE owners
ADD COLUMN email varchar(32);

ALTER TABLE owners
ADD COLUMN data_last_updated timestamp;

ALTER TABLE owners
DROP COLUMN data_last_updated;

UPDATE owners SET data_last_updated = random_date_in_range('2016-02-01', '2019-01-01');

CREATE OR REPLACE FUNCTION owners_timestamp() RETURNS trigger AS $$
BEGIN
    NEW.data_last_updated := now()::date;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS owners_timestamp ON owners;

SELECT version();

CREATE TRIGGER owners_timestamp BEFORE INSERT OR UPDATE ON owners
FOR EACH ROW EXECUTE PROCEDURE owners_timestamp();

SELECT * FROM owners WHERE email IS NULL OR email = '';

UPDATE owners
SET email = ''
WHERE email = NULL;

--@checking performance
UPDATE owners
SET streetaddress='71 Strandgade'
WHERE owner_id='1313';

SELECT data_last_updated,* FROM owners
WHERE city='Santa Monica';

-- added some fake emails and phone numbers in owners
UPDATE owners SET email = name;

UPDATE owners
SET email = CONCAT(email, '@gmail.com');

ALTER TABLE owners
ADD COLUMN phone varchar;

ALTER TABLE owners
ADD CONSTRAINT phone UNIQUE(surname);

UPDATE owners
SET phone = CONCAT(48, floor(random() * 9 + 1), floor(random() * 9 + 1), owner_id, floor(random() * 9 + 1));

ALTER TABLE owners ALTER COLUMN phone TYPE integer USING (trim(phone)::integer);

--@MT: check if present & create notice with performance
SELECT owner_id, surname, COALESCE(email,'Call to get email') FROM owners;

SELECT owner_id, surname,
COALESCE(NULLIF(email,''),phone::varchar) AS confirmation
FROM owners;

-- add notice
CREATE OR REPLACE FUNCTION raise_notice() RETURNS TRIGGER AS
$$
DECLARE
    arg TEXT;
BEGIN
    FOREACH arg IN ARRAY TG_ARGV LOOP
        RAISE NOTICE 'Check if you can find ''%''and add data during next visit',arg;
    END LOOP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER insert_notice BEFORE INSERT ON owners
FOR EACH ROW EXECUTE PROCEDURE raise_notice('phone','other information');

INSERT INTO owners VALUES ('1234', 'Roy', 'Krystyniak', '18 Olbrachta ', 'Warsaw', 'MI', 'Michigan', '02415', NULL, NULL, DEFAULT);

CREATE OR REPLACE FUNCTION full_name(owners) RETURNS varchar(62) AS $$
	SELECT $1.name || ' ' || $1.surname
$$ LANGUAGE SQL;

CREATE OR REPLACE FUNCTION contact_details(owners) RETURNS varchar(500) AS $$
	SELECT $1.streetaddress || ', ' || $1.city || ', ' || $1.state || ', ' || $1.phone|| ', ' || $1.email
$$ LANGUAGE SQL;

SELECT full_name(owners.*), contact_details(owners.*)
FROM owners;

--PROCEDURE table

--proceduresubcode unique? can be pk?:: no there are 6 - 01 and 5 - 02 etc
SELECT proceduresubcode as "procedures codes",
COUNT(*)::int as "number of procedures"
FROM procedure
GROUP BY proceduresubcode
ORDER BY proceduresubcode;

ALTER TABLE procedure
ADD PRIMARY KEY (procedureid);

ALTER TABLE procedure
ADD CONSTRAINT price CHECK (price >= 5 AND price <= 775);

--HISTORY table

SELECT COUNT(proceduretype) FROM history;

UPDATE history
SET petid = floor(random() * 101 + 1);

ALTER TABLE history ALTER COLUMN petid TYPE integer USING (trim(petid)::integer);

--check [%] structure of procedures
SELECT proceduretype,(COUNT(*)*100)/(SELECT COUNT(proceduretype) FROM history):: int AS SHARE
FROM history
GROUP BY proceduretype;

SHOW DateStyle;
SET DateStyle = 'ISO,DMY';

--set up value of quarter of year
ALTER TABLE history
ADD COLUMN recent_visit_Qy int;

UPDATE history
SET recent_visit_Qy = EXTRACT(QUARTER FROM proceduredate)::INTEGER;

CREATE OR REPLACE FUNCTION update() RETURNS trigger AS $$
DECLARE
    proceduredate date;
BEGIN
    NEW.recent_visit_Qy = EXTRACT(QUARTER FROM NEW.proceduredate)::INTEGER;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS update ON history;

CREATE TRIGGER update BEFORE INSERT OR UPDATE ON history
	FOR EACH ROW EXECUTE PROCEDURE update();

ALTER TABLE history
ADD CONSTRAINT recent_visit_Qy CHECK (recent_visit_Qy >= 1 AND recent_visit_Qy <= 4);

ALTER TABLE history
ADD COLUMN vetID int;

UPDATE history
SET vetID = floor(random() * 4 + 1);

ALTER TABLE history
ALTER COLUMN vetid SET DEFAULT 1;

--vet id from vet pool
ALTER TABLE history
ADD CONSTRAINT history_vetid_fkey
FOREIGN KEY (vetid) REFERENCES vets(vet_id)
ON UPDATE CASCADE
ON DELETE CASCADE;

--pet id from pet pool
ALTER TABLE history
ADD CONSTRAINT history_petid_fkey
FOREIGN KEY (petid) REFERENCES pets(pet_id)
ON UPDATE CASCADE
ON DELETE CASCADE;

SELECT petid,'not in pets table' AS note
FROM history
EXCEPT
	SELECT pet_id, 'not in pets table' AS note
	FROM pets;

--VETS table
ADD CONSTRAINT overhours CHECK (overhours >= 1 AND overhours <= 100);

--4. Insert data into tables

INSERT INTO history (petid,proceduredate,proceduretype,proceduresubcode, recent_visit_Qy, vetid)
VALUES (13,'2019-08-29','VACCINATIONS', '05', DEFAULT, 4);

INSERT INTO history (petid,proceduredate,proceduretype,proceduresubcode, recent_visit_Qy, vetid)
VALUES (108,'today'::abstime,'VACCINATIONS', '05',DEFAULT,2);
--MT: error: Key (petid)=(108) is not present in table "pets".

INSERT INTO pets (pet_id, name, kind, gender, age, owner_id, sign_up)
VALUES (102,'Gucio','Hamster','M',3,'5168', 'NOW'::abstime);

INSERT INTO owners
	(owner_id, name, surname, streetaddress, city, state, statefull, zipcode, email, phone, data_last_updated)
VALUES
	('1313', 'Anna','Jin', '3941 Ritter Avenue', 'Santa Monica', 'CA','California',02414, 'Jin@yahoo.com', 489087654, DEFAULT),
	('1111', 'Maria', 'Chin', '3941 Ritter Avenue', 'SanFrancisco','CA','California',02414,'', 489087654, DEFAULT),
	('0666','Wojtashek', 'Young', '3941 Ritter Avenue', 'Santa Monica','CA','California',02414,'young@yahoo.com', 489087654, DEFAULT),
	('0101', 'Bartek', 'Ho','3941 Ritter Avenue', 'Santa Monica','CA','California',02414,'ho@yahoo.com', 489087654, DEFAULT)
;

INSERT INTO procedure (proceduretype, proceduresubcode,description,price, procedureid)
VALUES ('ORTHOPEDIC','02','Casting',1500,21);
-- MT: Controlled error: new row for relation "procedure" violates check constraint "price"

INSERT INTO vets (name, address, vet_specialisation, salary_fixed, overhours_rate, overhours)
VALUES (ROW('John','M','Tyrmand'),ROW('777 Redutowa','Warsaw','MAZ','Masovian','01107'),ROW('Dog','yes', 'no'), 5400,120,10);

INSERT INTO vets (name, address, vet_specialisation, salary_fixed, overhours_rate, overhours)
VALUES (ROW('Holden','M','Caulfield'),ROW('132 Puste Pola','Warsaw','MAZ','Masovian','02107'),ROW('Cat','no', 'yes'), 7400,20.5,100);

INSERT INTO vets (name, address, vet_specialisation, salary_fixed, overhours_rate, overhours)
VALUES (ROW('Vivian','F','Maier'),ROW('112 Reduta','Warsaw','MAZ','Masovian','09807'),ROW('dog','yes', 'yes'), 1040,50,80);

INSERT INTO vets (name, address, vet_specialisation, salary_fixed, overhours_rate, overhours)
VALUES (ROW('Antoni','M','Gaudi'),ROW('132 Barca','Barcelona','CAT','Catalonia','12107'),ROW('Cat','yes', 'no'), 1700,39.5,100);

SELECT (name).surname, (address).city, (vet_specialisation).surgery, salary_fixed, overhours
FROM vets;

SELECT MAX(vet_id) FROM vets;

CREATE SEQUENCE IF NOT EXISTS vets_vetid_seq
START WITH 5 OWNED BY vets.vet_id;

INSERT INTO vets (vet_id, name, address, vet_specialisation, salary_fixed, overhours_rate, overhours)
VALUES (2, ROW('Antoni','M','Gaudi'),ROW('132 Barca','Barcelona','CAT','Catalonia','12107'),ROW('Cat','yes', 'no'), 1700,39.5,100);
--MT: error: controlled error - good, it is controlled sequence and also 'unique'

--terminal
psql -p 5432 -h localhost -d VETERINARY -U postgres
\COPY vets TO 'vets_final.csv' WITH (FORMAT CSV, HEADER, QUOTE '"',FORCE_QUOTE (vet_id, name,address, vet_specialisation, salary_fixed, overhours_rate, overhours));
\q
head vets_final.csv

--5. General database and table information

--all tables in the currently connected database
SELECT * FROM INFORMATION_SCHEMA.TABLES;
SELECT * FROM INFORMATION_SCHEMA.VIEWS;

--my tables in the currently connected database
SELECT *
FROM pg_catalog.pg_tables
WHERE schemaname != 'pg_catalog' AND schemaname != 'information_schema';

--show columns in my tables
SELECT column_name, data_type FROM information_schema.columns WHERE TABLE_NAME = 'pets';
SELECT column_name, data_typeFROM information_schema.columns WHERE TABLE_NAME = 'owners';
SELECT column_name, data_type FROM information_schema.columns WHERE TABLE_NAME = 'vets';
SELECT column_name, data_type FROM information_schema.columns WHERE TABLE_NAME = 'procedure';
SELECT column_name, data_type FROM information_schema.columns WHERE TABLE_NAME = 'history';

-- database size
SELECT
    pg_database.datname,
    pg_size_pretty(pg_database_size(pg_database.datname)) AS size
    FROM pg_database;

-- table size
SELECT pg_relation_size('pets'),
  pg_size_pretty(pg_relation_size('pets'));

-- all tables size
SELECT
    relname AS "relation",
    pg_size_pretty (
        pg_total_relation_size (C .oid)
    ) AS "total_size"
FROM
    pg_class C
LEFT JOIN pg_namespace N ON (N.oid = C .relnamespace)
WHERE
    nspname NOT IN (
        'pg_catalog',
        'information_schema'
    )
AND C .relkind <> 'i'
AND nspname !~ '^pg_toast'
ORDER BY
    pg_total_relation_size (C .oid) DESC
LIMIT 6;

--6. Actual analysis

-- in which city is the highest number of clients?:: Southfield
SELECT city,
COUNT(city) AS "client_number"
FROM owners
GROUP BY city
ORDER BY "client_number" DESC
LIMIT 1;

-- client structure by pet kind?:: dog/ cat/ parrot
SELECT kind,
COUNT(kind) AS "client_number"
FROM pets
GROUP BY kind
ORDER BY "client_number" DESC
LIMIT 5;

--what is the most prevalent adult dog age? top 3?:: 12,4 and 5 yo
SELECT pets.age, COUNT(owners.owner_id) as "summary number of pet owners"
FROM pets
JOIN owners ON pets.owner_id=owners.owner_id
where pets.age > 3 and pets.kind='Dog'
GROUP BY pets.age
ORDER BY COUNT(owners.owner_id) desc
Limit 3;

-- in which quater were highest number of visits? top 2? :: 1st and 3rd quater
SELECT recent_visit_Qy,
COUNT(recent_visit_Qy) AS "visit_occurrence"
FROM history
GROUP BY recent_visit_Qy
ORDER BY "visit_occurrence" DESC
LIMIT 2;

--calculate revenue stream (individual and summary) by clients gender, pet kind and age structure
SELECT gender, kind, age, SUM(h.price) as "total sum"
FROM pets
JOIN history o on pets.pet_id=o.petid
JOIN procedure h on o.proceduresubcode=h.proceduresubcode
where age > 1
GROUP BY gender, ROLLUP (kind, age);

-- what procedure (subcode, type,decribtion) was the most frequent? top 7?
SELECT r.proceduresubcode,r.proceduretype, r.description,
COUNT(proceduredate)::int as "number of vists"
FROM history
JOIN procedure r ON history.proceduresubcode = r.proceduresubcode
GROUP BY r.description, r.proceduretype, r.proceduresubcode
ORDER BY "number of vists" desc
LIMIT 7;

-- which owner (by surname) spend most money(pln)? top 3?
SELECT a.surname,
COUNT(proceduredate)::int as "total number of vists",
SUM(r.price)::int as "total_costs"
FROM history
JOIN procedure r ON history.proceduresubcode = r.proceduresubcode
JOIN pets p ON history.petid = p.pet_id
JOIN owners a ON p.owner_id = a.owner_id
GROUP BY a.surname
ORDER BY "total_costs" desc
LIMIT 3;

-- show type and short description, frequency and total agg cost of procedures which are cheaper than 1000pln in 2016
SELECT h.proceduretype as "type of procedure",procedure.description as "short decsription",
COUNT(proceduredate)::int AS "frequency of procedure",
(SUM(procedure.price)) AS "total procedure cost"
FROM history h
JOIN procedure ON h.proceduretype=procedure.proceduretype
WHERE proceduredate BETWEEN '2016-01-01' AND '2016-12-30'
GROUP BY h.proceduretype, procedure.price,procedure.description
HAVING (COUNT(proceduredate)) * procedure.price <1000
ORDER BY "total procedure cost" DESC;

-- show type and short description, frequency and total agg cost of procedures which are more expensive han 100 k pln in first half of 2016
SELECT h.proceduretype as "type of procedure",procedure.description as "short decsription",
COUNT(proceduredate)::int AS "frequency of procedure",
(COUNT(proceduredate)) * procedure.price AS "total procedure cost"
FROM history h
JOIN procedure ON h.proceduretype=procedure.proceduretype
WHERE proceduredate BETWEEN '2016-01-01' AND '2016-06-30'
GROUP BY h.proceduretype, procedure.price,procedure.description
HAVING (COUNT(proceduredate)) * procedure.price >100000
ORDER BY "total procedure cost" DESC;

--compare salary - in which percentile fixed contracts are vets in clinic?
SELECT
vet_id,
	salary_fixed,
    PERCENT_RANK() OVER (
        ORDER BY salary_fixed
    )
FROM
    vets;

--oldest dog?
SELECT MAX(age)::numeric(4,1)
FROM pets
WHERE kind='Dog';

--dog number by age structure?
SELECT age as "dog age",
COUNT(*)::int as "number of dogs"
FROM pets
WHERE (kind='Dog')
AND Age >= 0
GROUP BY age
ORDER BY age;

-- which animal (by name) was the most frequently in vet? top 3?
SELECT a.pet_id, a.name, a.kind, a.age, r.proceduresubcode,
COUNT(proceduredate)::int as "number of vists"
FROM history
JOIN procedure r ON history.proceduresubcode = r.proceduresubcode
JOIN pets a ON history.petid = a.pet_id
GROUP BY r.proceduresubcode, a.name, a.kind, a.age, a.pet_id
ORDER BY "number of vists" desc
LIMIT 3;

--show pet name, date of visit, number of visits and each time what was cost of visits for clients from Detroit?
SELECT petid, p.name as "pet name", proceduredate, COUNT(proceduredate)::int as "number of vists", SUM(n.price) as "cost of vists"
FROM history
JOIN pets p ON p.pet_id=history.petid
JOIN procedure n ON n.proceduresubcode=history.proceduresubcode
WHERE petid = ANY (SELECT pet_id FROM pets
                         JOIN owners o ON pets.owner_id=o.owner_id
                         WHERE o.city = 'Detroit')
GROUP BY petid, p.name, n.price, proceduredate
ORDER BY "cost of vists" desc;

SELECT h.*, SUM(p.price)
FROM history h
JOIN procedure p ON p.proceduresubcode=h.proceduresubcode
WHERE petid = 54
GROUP BY h.petid, h.proceduredate, h.proceduretype, h.proceduresubcode, h.recent_visit_qy, h.vetid;

--show most expensive treatment price for selected petid?
SELECT p.price, h.petid, h.proceduresubcode, p.description, h.proceduredate
from procedure p
JOIN history h ON p.proceduretype=h.proceduretype
WHERE h.petid =9
ORDER BY p.price desc
LIMIT 10;

CREATE OR REPLACE FUNCTION most_expensive(pid integer) RETURNS int AS $$
SELECT MAX(procedure_cost) FROM
(SELECT DISTINCT(h.petid), p.price::int AS procedure_cost
FROM history h
JOIN procedure p ON h.proceduretype=p.proceduretype
WHERE h.petid=pid
GROUP BY h.petid,p.price) as agg_cost
$$ LANGUAGE SQL;

SELECT most_expensive(8);
SELECT most_expensive(1);
SELECT most_expensive(32);
SELECT most_expensive(35);
SELECT most_expensive(9);
SELECT most_expensive(4);

SELECT p.price, h.petid, h.proceduresubcode, p.description, h.proceduredate
from procedure p
JOIN history h ON p.proceduretype=h.proceduretype
WHERE h.petid=8
ORDER BY p.price desc
LIMIT 4;

SELECT p.price, h.petid, h.proceduresubcode, p.description, h.proceduredate
from procedure p
JOIN history h ON p.proceduretype=h.proceduretype
WHERE h.petid=4
ORDER BY p.price desc
LIMIT 4;

SELECT p.price, h.petid, h.proceduresubcode, p.description, h.proceduredate
from procedure p
JOIN history h ON p.proceduretype=h.proceduretype
WHERE h.petid=32
ORDER BY p.price desc
LIMIT 4;

SELECT p.price, h.petid, h.proceduresubcode, p.description, h.proceduredate
from procedure p
JOIN history h ON p.proceduretype=h.proceduretype
WHERE p.description='B4-9432'
ORDER BY p.price desc
LIMIT 4;

--create adult pet view (older than 2 yo) who is paying more than 50 pln per treatment and find
--a)for pet 13 what is total number and price of all treatments by which vet?
--b) price of all treatments for dog segment
--c) pet name of owner 5447
--c) number of procedures during summer months?

CREATE VIEW pets_overview AS
SELECT pet_id,pets.name as pet_name, kind,o.owner_id, o.name as owner_name, o.surname as owner_surname, h.proceduredate, h.proceduretype, p.price, p.description, v.name as vet_name
FROM pets
JOIN owners o on pets.owner_id=o.owner_id
JOIN history h on pets.pet_id=h.petid
JOIN procedure p on h.proceduresubcode=p.proceduresubcode
JOIN vets v on h.vetid=v.vet_id
WHERE age >=2 AND p.price > 50;

SELECT pet_name, COUNT(proceduredate) as "total_number_of_procedures", SUM(price)as "total_cost_of_procedures", vet_name
FROM pets_overview
WHERE pet_id =13
GROUP BY vet_name, pet_name;

SELECT SUM(price)as "total_cost_of_procedures_dog_segment"
FROM pets_overview
WHERE kind ='Dog';

SELECT "pet_name"
FROM pets_overview
WHERE owner_id ='5447'
LIMIT 1;

SELECT COUNT(*)
FROM pets_overview
where proceduredate BETWEEN '2016-06-01' AND '2016-09-01';

-- describe treatment price range?
SELECT ProcedureType,Price,
CASE WHEN price<25 THEN 'inexpensive'
     WHEN price>=25 AND price<=100 THEN 'mid-range'
	 WHEN price > 100 THEN 'premium'
END AS "price description"
FROM procedure;
--MT: Total query runtime: 14 msec

CREATE OR REPLACE FUNCTION treatment_price_category(price real) RETURNS text AS $$
BEGIN
	IF price > 100.0 THEN
		RETURN 'premium';
	ELSIF price >= 25.0 THEN
		RETURN 'mid-range';
	ELSE
		RETURN 'inexpensive';
	END IF;
END;
$$ LANGUAGE plpgsql;

SELECT treatment_price_category(price),*
FROM procedure;
--MT: Total query runtime: 13 msec

--most expensive procedure?
SELECT proceduresubcode, description, MAX(Price) as "most_expensive_procedure"
FROM procedure
GROUP BY proceduresubcode, description
ORDER BY "most_expensive_procedure" desc
LIMIT 1;

--avg price of each procedure type?
SELECT DISTINCT(ProcedureType), AVG(Price)::int as "avg_price_procedure"
FROM procedure
GROUP BY procedureType
ORDER BY "avg_price_procedure" desc;

--calculate brutto price (incl VAT) of all offers
CREATE OR REPLACE FUNCTION price_incl_vat(procedure, increase_percent numeric)
RETURNS numeric AS $$
	SELECT $1.price * increase_percent/100
$$ LANGUAGE SQL

SELECT proceduresubcode,proceduretype,description,price, price_incl_vat(procedure.*,123)::int
FROM procedure;

SELECT proceduresubcode,proceduretype,description,price, price_incl_vat(procedure.*,108)::int
FROM procedure;

--vet surgeon with highest salary
SELECT (name).surname, (vet_specialisation).surgery, salary_fixed, (salary_fixed + overhours_rate * overhours) as total_salary
FROM vets
WHERE (vet_specialisation).surgery = 'yes'
ORDER BY total_salary DESC;

--vet with highest salary in total pool of vets
CREATE OR REPLACE FUNCTION max_contract_salary() RETURNS numeric AS $$
	SELECT MAX(salary_fixed)
	FROM vets;
$$ LANGUAGE SQL;

SELECT max_contract_salary();

--vet salary min, max, avg in vets pool
SELECT
  count(vet_id) as "number of vets",
  count(case when overhours = 0 then 0 else null end) as "only fixed contract",
  count(case when overhours != 0 then 1 else null end) as "fixed contract plus overhours",
  min(salary_fixed + overhours*overhours_rate) as "min total salary",
  max(salary_fixed + overhours*overhours_rate) as "max total salary",
  avg(salary_fixed + overhours*overhours_rate)::numeric(4,0) as "avg total salary"
FROM vets;

--vets work cost? cost per hour (fixed & over hours & total) and productivity
SELECT (name).surname,
(overhours+40) as all_working_hours,
COUNT(r.proceduredate) as total_treatments_j,
(COUNT(r.proceduredate)/(overhours+40))::numeric(4,0) as procedures_per_h,
(salary_fixed/40)::numeric(4,0) as fixed_contract_pln_per_h,
((salary_fixed + overhours*overhours_rate)/(overhours+40))::numeric(4,0) as total_contract_pln_per_h
FROM vets
JOIN history r ON vets.vet_id = r.vetID
GROUP BY (name).surname, overhours, salary_fixed, overhours_rate
Having COUNT(r.proceduredate) > 365;

-- create special rabis table only for dogs
CREATE TABLE rabis AS
SELECT petid, proceduredate, kind FROM
(SELECT DISTINCT(petid), p.kind as "kind", proceduredate, n.proceduresubcode
FROM history
JOIN pets p ON p.pet_id=history.petid
JOIN procedure n ON n.proceduresubcode=history.proceduresubcode
WHERE n.proceduresubcode = ANY (SELECT proceduresubcode FROM procedure WHERE n.description = 'Rabies')
GROUP BY petid, p.kind, n.price, n.proceduresubcode, proceduredate) as easter_egg
WHERE "kind" = 'Dog';

ALTER TABLE rabis
ADD COLUMN next_visit date;

SHOW intervalstyle;

UPDATE rabis
SET next_visit = proceduredate + INTERVAL '1 Year';

CREATE OR REPLACE FUNCTION next_vaccination() RETURNS trigger AS $$
DECLARE
    proceduredate date;
BEGIN
    NEW.next_visit = NEW.proceduredate + INTERVAL '1 Year';
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS next_vaccination ON rabis_dogs;

CREATE TRIGGER next_vaccination BEFORE INSERT OR UPDATE ON rabis_dogs
	FOR EACH ROW EXECUTE PROCEDURE next_vaccination();

--terminal
pg_dump VETERINARY -p 5432 -h localhost  -U postgres > veterinary.sql
head veterinary.sql
createdb veter_bakup -p 5432 -h localhost -U postgres
psql veter_bakup -p 5432 -h localhost -U postgres <  veterinary.sql
ls -l veterinary.*