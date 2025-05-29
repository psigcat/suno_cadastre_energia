
DROP TABLE IF EXISTS [SCHEMA_NAME].building_part_plus CASCADE;
CREATE TABLE [SCHEMA_NAME].building_part_plus AS
SELECT 
   --b.ogc_fid as id, b.geom as geom,
   b.id as id, b.geom as geom,
   b.localid::text, 
   left(b.localid, 14)::text as refcat, 
   replace(substr(b.localid, 16), 'part', '')::integer as part, 
   b.referencegeometry, b.numberoffloorsaboveground,
   b.heightbelowground, b.heightbelowground_uom,
   b.numberoffloorsbelowground
FROM cadastre_input.[TABLE_BUILDING_PART] as b;

-- definimos la Primary Key, 
alter table [SCHEMA_NAME].building_part_plus ADD PRIMARY KEY (id);

