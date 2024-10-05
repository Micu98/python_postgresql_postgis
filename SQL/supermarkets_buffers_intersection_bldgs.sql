-- Create supermarket buffers (1000 m) for all supermarkets in selected postcode areas
-- Dieser SQL-Code erstellt Pufferzonen mit einem Radius von 1000 Metern um Supermärkte in den Postleitzahlbereichen 8001 und 8055 in Zürich. 
-- Die Ergebnisse beinhalten die OSM-ID des Supermarkts sowie die Geometrie der Pufferzone, transformiert in das Koordinatensystem EPSG:4326.
WITH supermarket_buffers AS (
    SELECT
        p.osm_id AS supermarket_osm_id,
        ST_TRANSFORM(ST_Buffer(p.way::geometry, 1000, 'quad_segs=8'), 4326) AS buffer_geom -- Diese Funktion erzeugt einen Buffer (eine Pufferzone) um den Standort des Supermarkts. Diese Option steuert, wie rund der Puffer aussieht. 
    FROM
        public.planet_osm_point AS p
    WHERE
        p.shop = 'supermarket'
        AND p."addr:postcode" IN ('8001', '8055')
),

-- Preselection of buildings (to reduce data size)
-- Der Code erstellt eine temporäre Tabelle namens buildings, die alle Gebäude in Zürich enthält, die eine Straßenadresse haben.
-- Für jedes Gebäude werden die OSM-ID, die Straßenadresse, die Hausnummer, die Postleitzahl, und die transformierte Geometrie des Gebäudes (in WGS 84-Koordinaten) zurückgegeben.
buildings AS (
    SELECT
        p.osm_id AS building_osm_id, -- Hier wird die OpenStreetMap-ID (osm_id) jedes Gebäudes abgerufen und als building_osm_id bezeichnet
        p."addr:street",
        p."addr:housenumber",
        p."addr:city",
        p."addr:postcode",
        ST_TRANSFORM(p.way, 4326) AS geom
    FROM
        public.planet_osm_polygon AS p
    WHERE
        p."addr:street" IS NOT NULL
        AND p."addr:city" = 'Zürich'
)

-- Select buildings inside supermarket buffers
-- Diese Abfrage findet Gebäude in Zürich, die sich innerhalb einer 1 km Pufferzone um einen Supermarkt befinden. 
-- Sie prüft, ob die Geometrien von Gebäuden und Pufferzonen sich überschneiden, und gibt die relevanten Daten der Gebäude und Supermärkte zurück.
SELECT
    b.building_osm_id,
    b."addr:street",
    b."addr:housenumber",
    b."addr:city",
    b."addr:postcode",
    b.geom AS building_geom,
    s.supermarket_osm_id,
    s.buffer_geom AS buffer_geom
FROM
    buildings AS b
JOIN
    supermarket_buffers AS s ON ST_Intersects(b.geom, s.buffer_geom::geometry);


    -- ganzer Code eingeben für schlussendliches Ergebnis