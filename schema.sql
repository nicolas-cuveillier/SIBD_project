-- Drop all the precedent tables
DO $$ DECLARE
  r RECORD;
BEGIN
  FOR r IN (SELECT tablename FROM pg_tables WHERE schemaname = current_schema()) LOOP
    EXECUTE 'DROP TABLE ' || quote_ident(r.tablename) || ' CASCADE';
  END LOOP;
END $$;

CREATE TABLE country(
    flag VARCHAR(20) NOT NULL,
    name VARCHAR(70),
    iso_code VARCHAR(20) NOT NULL,
    PRIMARY KEY(name)
    -- a country has a unique standard ISO code
    -- every country where boats are registered must have at least one location
);

CREATE TABLE location(
    name VARCHAR(70) NOT NULL,
    latitude NUMERIC(8,6),
    longitude NUMERIC(9,6),
    country_name VARCHAR(70) NOT NULL,
    PRIMARY KEY(latitude,longitude),
    FOREIGN KEY (country_name) REFERENCES country(name)
    -- every country where boats are registered must have at least one location
);

CREATE TABLE boat_class (
    name VARCHAR(70),
    max_length NUMERIC(5,2) NOT NULL,
    PRIMARY KEY (name)
);

CREATE TABLE boat(
    name VARCHAR(70) NOT NULL,
    length NUMERIC(5,2) NOT NULL,
    year_of_registration INTEGER NOT NULL,
    country_name VARCHAR(70),
    cni VARCHAR(20),
    boat_class_name VARCHAR(70) NOT NULL,
    PRIMARY KEY (country_name, cni),
    FOREIGN KEY (country_name) REFERENCES country(name),
    FOREIGN KEY (boat_class_name) REFERENCES boat_class(name)
    -- CHECK ( length < (SELECT max_length FROM boat_class WHERE boat_class_name = boat_class.name))
    -- every country where boats are registered must have at least one location
    -- the skipper must be an authorized sailor of the corresponding reservation
);

CREATE TABLE date_Interval(
    start_date DATE,
    end_date DATE,
    PRIMARY KEY (start_date, end_date),
    CHECK ( start_date < end_date )
    -- a boat cannot take off on a trip before the reservation date
);

CREATE TABLE sailor(
    firstname VARCHAR(80) NOT NULL,
    surname VARCHAR(80) NOT NULL,
    email VARCHAR(254),
    PRIMARY KEY (email)
    -- sailor should be either senior or junior
);

CREATE TABLE junior(
    email VARCHAR(254),
    PRIMARY KEY (email),
    FOREIGN KEY (email) REFERENCES sailor(email)
);

CREATE TABLE senior(
    email VARCHAR(254),
    PRIMARY KEY (email),
    FOREIGN KEY (email) REFERENCES sailor(email)
);

CREATE TABLE reservation(
    start_date DATE,
    end_date DATE,
    country_name VARCHAR(70),
    cni VARCHAR(20),
    email VARCHAR(254),
    PRIMARY KEY (start_date, end_date, country_name, cni),
    FOREIGN KEY (country_name, cni) REFERENCES boat(country_name,cni),
    FOREIGN KEY (start_date, end_date) REFERENCES date_Interval(start_date, end_date),
    FOREIGN KEY (email) REFERENCES senior(email)
    -- any two location ust be at least one nautical mile apart
    -- the skipper must be an authorized sailor of the corresponding reservation
    -- one of the senior authorized sailors must be the responsible of the reservation
    -- every reservation must exist in the table authorized
);

CREATE TABLE trip(
    take_off DATE,
    arrival DATE NOT NULL,
    insurance VARCHAR(20) NOT NULL,
    start_date DATE,
    end_date DATE,
    country_name VARCHAR(70),
    cni VARCHAR(20),
    from_latitude NUMERIC(8,6) NOT NULL,
    from_longitude NUMERIC(9,6) NOT NULL,
    to_latitude NUMERIC(8,6) NOT NULL,
    to_longitude NUMERIC(9,6) NOT NULL,
    sailor_email VARCHAR(254) NOT NULL,
    PRIMARY KEY (start_date, end_date, country_name, cni, take_off),
    FOREIGN KEY (start_date, end_date, country_name, cni)  REFERENCES reservation(start_date, end_date, country_name, cni),
    FOREIGN KEY (from_latitude,from_longitude) REFERENCES location(latitude,longitude),
    FOREIGN KEY (to_latitude,to_longitude) REFERENCES location(latitude,longitude),
    FOREIGN KEY (sailor_email) REFERENCES sailor(email),
    CHECK ( arrival > take_off ),
    CHECK ( take_off > start_date AND arrival < end_date)
    -- a boat cannot take off on a trip before the reservation date
    -- the skipper must be an authorized sailor of the corresponding reservation
);

CREATE TABLE authorized(
    email VARCHAR(254),
    start_date DATE,
    end_date DATE,
    country_name VARCHAR(70),
    cni VARCHAR(20),
    PRIMARY KEY (start_date,end_date,cni,country_name, email),
    FOREIGN KEY (email) REFERENCES sailor(email),
    FOREIGN KEY (start_date,end_date,cni,country_name) REFERENCES reservation(start_date,end_date,cni,country_name)
    -- one of the senior authorized sailors must be the responsible of the reservation
);

CREATE TABLE sailing_certificate (
    issue_date DATE,
    expiry_date DATE NOT NULL,
    email VARCHAR(254),
    boat_class_name VARCHAR(70) NOT NULL,
    PRIMARY KEY (issue_date, email),
    FOREIGN KEY (email) REFERENCES sailor(email),
    FOREIGN KEY (boat_class_name) REFERENCES boat_class(name),
    CHECK ( issue_date < expiry_date )
    -- Every sailing certificate must exist in the table 'valid_for'
);



CREATE TABLE valid_for (
    issue_date DATE,
    country_name VARCHAR(70),
    sailor_email VARCHAR(254),
    PRIMARY KEY (issue_date,sailor_email,country_name),
    FOREIGN KEY (issue_date, sailor_email) REFERENCES sailing_certificate(issue_date, email),
    FOREIGN KEY (country_name) REFERENCES country(name)
);