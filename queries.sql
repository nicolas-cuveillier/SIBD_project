-- The name of all boats that are used in some trip
SELECT DISTINCT name FROM boat NATURAL JOIN trip WHERE boat.cni = trip.cni;

-- The name of all boats that are not used in any trip
SELECT DISTINCT name FROM boat WHERE name NOT IN (SELECT name FROM boat NATURAL JOIN trip WHERE boat.cni = trip.cni);

-- The name of all boats registered in 'PRT' (ISO code) for which at least one responsible for a reservation
-- has a surname that ends with 'Santos'
SELECT DISTINCT boat.name FROM boat NATURAL JOIN reservation NATURAL JOIN sailor
WHERE (country_name IN (SELECT name FROM country WHERE iso_code = 'PRT') AND sailor.surname LIKE '%Santos');

-- The full name of all skippers without any certificate corresponding to the class of the trip's boat
SELECT (firstname,surname) FROM sailor JOIN trip t on sailor.email = t.sailor_email
WHERE (email NOT IN (SELECT email FROM sailing_certificate));