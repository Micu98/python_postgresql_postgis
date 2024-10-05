-- Select supermarkets with defined distance to motorways.
SELECT p.osm_id,
	p."addr:street",
	p."addr:housenumber",
	p."addr:city",
	p."addr:postcode",
	p.SHOP,
	UPPER(p.name) AS brand,
	ST_TRANSFORM(P.WAY, 4326) AS geom
FROM public.planet_osm_point AS p
WHERE p.SHOP = 'supermarket'
	AND p."addr:street" IS NOT NULL
	AND p."addr:housenumber" IS NOT NULL
	AND p."addr:city" IS NOT NULL
	AND p."addr:postcode" IS NOT NULL
	AND EXISTS -- Diese Bedingung stellt sicher, dass nur Supermärkte ausgewählt werden, die innerhalb einer bestimmten Entfernung zu einer Autobahn liegen.
		(SELECT 1
			FROM public.planet_osm_roads AS lr -- Diese Tabelle enthält Straßendaten aus OpenStreetMap. Der Alias lr steht hier für "line roads"
			WHERE lr.highway IN ('motorway')
				AND ST_DWITHIN(p.way::geometry, lr.way::geometry, 1000)); -- Diese Funktion prüft, ob sich der Supermarkt innerhalb von 1000 Metern (1 km) von einer Autobahn befindet