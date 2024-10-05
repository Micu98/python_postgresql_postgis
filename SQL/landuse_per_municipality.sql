-- landuse tags for green spaces in OSM data
-- landuse=forest 					- Areas with forestry or woodland vegetation.
-- landuse=grass 					- Areas covered in grass.
-- landuse=greenfield 				- Undeveloped land reserved for urban development.
-- landuse=garden 					- Private or community gardens.
-- landuse=meadow 					- Fields or meadows, often used for agriculture or left to nature.
-- landuse=orchard 				    - Areas planted with fruit trees.
-- landuse=vineyard 				- Areas used for growing grapes.
-- landuse=cemetery 				- Land designated for burial.
-- landuse=recreation_ground 		- Open spaces for general recreation.
-- landuse=village_green 	  		- Common in British English for open space at a village’s heart.
-- landuse=allotments 				- Areas of land rented for growing food plants.
-- landuse=conservation 			- Land primarily used for conservation purposes.
-- landuse=greenhouse_horticulture - Areas with greenhouses for growing plants.

-- leisure Tags for parks and recreational areas
-- leisure=park 					- Urban or suburban areas dedicated to recreation, often green.
-- leisure=garden 					- Managed areas of planted flowers, trees, etc., possibly with paths and seating.
-- leisure=golf_course 			    - Areas used for playing golf.
-- leisure=nature_reserve 			- Protected areas for conservation and limited recreation.
-- leisure=playground 				- Outdoor areas designed for children to play.
-- leisure=pitch 					- Areas for playing team sports.
-- leisure=green 					- Used for village greens and similar.
-- leisure=sports_centre 			- Large areas that include facilities for various sports, often including green spaces.

-- Query landuse and calculate area
-- Dieser Code sucht nach grünen Flächen (z.B. Wälder, Wiesen) oder Freizeitflächen (z.B. Parks, Sportzentren) in der Stadt Zürich.
-- Er berechnet die Fläche dieser Gebiete in Quadratmetern und gibt ihre Geometrie in einem globalen Koordinatensystem (EPSG:4326) zurück.
-- Es werden nur die Gebiete ausgewählt, die sich vollständig innerhalb der Stadtgrenzen von Zürich befinden.
SELECT
    p.osm_id,
    COALESCE(p.landuse, p.leisure) AS landuse_leisure,
    ST_Area(ST_Transform(p.way, 32632)) AS area_sqm, --Berechnet die Fläche des Gebiets in Quadratmetern (m²). Dafür wird die Geometrie (way) in das UTM-Koordinatensystem 32N (SRID 32632) transformiert
    ST_Transform(p.way, 4326) AS geom -- Transformiert die Geometrie (way) in das WGS 84-Koordinatensystem (EPSG:4326), das für GPS-Daten und geografische Abfragen verwendet wird.
FROM
    public.planet_osm_polygon AS p
JOIN
    public.planet_osm_polygon AS z ON ST_Contains(z.way, p.way) -- ein Polygon z (das Zürich repräsentiert) das Polygon p (das die Landnutzung oder Freizeitnutzung repräsentiert) vollständig enthält. Dies wird durch die Funktion ST_Contains erreicht, die überprüft, ob sich ein Polygon innerhalb eines anderen befindet.
WHERE
    (p.landuse IN ('forest',
					'grass',
					'greenfield',
					'garden',
					'meadow',
					'orchard',
					'vineyard',
					'cemetery',
					'recreation_ground',
					'village_green',
					'allotments',
					'conservation',
					'greenhouse_horticulture')
    OR p.leisure IN ('park',
					'garden',
					'golf_course',
					'nature_reserve',
					'playground',
					'pitch',
					'green',
					'sports_centre'))
    AND z.admin_level = '8'
    AND z.name = 'Zürich';

-- Aggregate area by landuse type
-- Der Code berechnet die Gesamtfläche für bestimmte grüne Flächen (wie Wälder, Wiesen, Gärten) oder Freizeiteinrichtungen (wie Parks, Spielplätze) innerhalb der Stadt Zürich.
-- Es gruppiert diese Flächen nach ihrer Art (Landnutzung oder Freizeit) und sortiert sie nach der Gesamtfläche in Quadratmetern in absteigender Reihenfolge.
SELECT
    COALESCE(p.landuse, p.leisure) AS landuse_leisure, --  Die Funktion COALESCE gibt den ersten nicht-leeren Wert zurück. Hier prüft sie, ob p.landuse einen Wert hat; falls nicht, wird p.leisure verwendet
    SUM(ST_Area(ST_Transform(p.way, 32632))) AS total_area_sqm -- Hier wird die Gesamtfläche der Polygone berechnet.
FROM
    public.planet_osm_polygon AS p
JOIN
    public.planet_osm_polygon AS z ON ST_Contains(z.way, p.way)
WHERE
    (p.landuse IN ('forest',
		  'grass',
		  'greenfield',
		  'garden',
		  'meadow',
		  'orchard',
		  'vineyard',
		  'cemetery',
		  'recreation_ground',
		  'village_green',
		  'allotments',
		  'conservation',
		  'greenhouse_horticulture')
    OR p.leisure IN ('park',
		      'garden',
		      'golf_course',
		      'nature_reserve',
		      'playground',
		      'pitch',
		      'green',
		      'sports_centre'))    
AND z.admin_level = '8'
AND z.name = 'Zürich'
GROUP BY landuse_leisure
ORDER BY total_area_sqm DESC;