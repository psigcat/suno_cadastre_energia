
-- creo una nova taula amb els atributs tipo, any_reforma, parcela, sup_total, sup_terrassa, sup_calef, codi_dgc, us, clima, any_const

drop table if exists [SCHEMA_NAME].edificis cascade;
create table [SCHEMA_NAME].edificis as
select * from [SCHEMA_NAME].catupload;
	
alter table [SCHEMA_NAME].edificis 
	add column tipo character varying
--	add column any_reforma character varying,
--	add column parcela character varying,
--	add column sup_total character varying,
--	add column sup_terrassa character varying,
--	add column sup_calef character varying,
--	add column codi_dgc character varying,
--	add column us character varying,
--	add column clima character varying,
--	add column any_const character varying
;


-- duplico la columna amb totes les dades
update [SCHEMA_NAME].edificis as e
 set tipo = e.cat;

-- deixo només els 2 primers dígits de la columna tipo
update [SCHEMA_NAME].edificis  set 
tipo = SUBSTRING(tipo FROM 1 FOR 2);

-- creo en una taula per treballar amb els atributs tipus 13
drop table if exists [SCHEMA_NAME].edificis13 cascade;
create table [SCHEMA_NAME].edificis13 as
select * from [SCHEMA_NAME].edificis;

-- creo en una taula per treballar amb els atributs tipus 14
drop table if exists [SCHEMA_NAME].edificis14 cascade;
create table [SCHEMA_NAME].edificis14 as
select * from [SCHEMA_NAME].edificis;

-- deixo només les dades de tipo 14 de la taula edificis14  i el mateix per la 13, elimino la resta

DELETE FROM [SCHEMA_NAME].edificis14 WHERE tipo <> '14';
DELETE FROM [SCHEMA_NAME].edificis13 WHERE tipo <> '13';


-- taula 13, creo columna amb la parcela
alter table [SCHEMA_NAME].edificis13 
	add column if not exists parcela character varying;
update [SCHEMA_NAME].edificis13 set parcela = cat;
update [SCHEMA_NAME].edificis13 set 
	parcela = substring(parcela from 31 for 14);

-- taula 13, creo columna amb any de construccio
alter table [SCHEMA_NAME].edificis13 
	add column if not exists any_const character varying;
update [SCHEMA_NAME].edificis13 set any_const = cat;
update [SCHEMA_NAME].edificis13 set 
	any_const = substring(any_const from 296 for 4);

-- taula 13, creo columna amb codi_ine
alter table [SCHEMA_NAME].edificis13 
	add column if not exists codi_ine character varying;
update [SCHEMA_NAME].edificis13 set codi_ine = cat;
update [SCHEMA_NAME].edificis13 set 
	codi_ine = substring(codi_ine from 81 for 3);

-- taula 13, creo columna amb nom municipi
alter table [SCHEMA_NAME].edificis13 
	add column if not exists nom_muni character varying;
update [SCHEMA_NAME].edificis13 set nom_muni = cat;
update [SCHEMA_NAME].edificis13 set 
	nom_muni = substring(nom_muni from 84 for 40);

-- taula 13, creo columna amb tipus_via
alter table [SCHEMA_NAME].edificis13 
	add column if not exists tipus_via character varying;
update [SCHEMA_NAME].edificis13 set tipus_via = cat;
update [SCHEMA_NAME].edificis13 set 
	tipus_via = substring(tipus_via from 159 for 5);
	
-- taula 13, creo columna amb nom_via
alter table [SCHEMA_NAME].edificis13 
	add column if not exists nom_via character varying;
update [SCHEMA_NAME].edificis13 set nom_via = cat;
update [SCHEMA_NAME].edificis13 set 
	nom_via = substring(nom_via from 164 for 25);
	
-- taula 13, creo columna amb num_via
alter table [SCHEMA_NAME].edificis13 
	add column if not exists num_via character varying;
update [SCHEMA_NAME].edificis13 set num_via = cat;
update [SCHEMA_NAME].edificis13 set 
	num_via = substring(num_via from 189 for 4);

-- taula 13, creo columna amb lletra_via
alter table [SCHEMA_NAME].edificis13 
	add column if not exists lletra_via character varying;
update [SCHEMA_NAME].edificis13 set lletra_via = cat;
update [SCHEMA_NAME].edificis13 set 
	lletra_via = substring(lletra_via from 193 for 1);
	
    
    
    -- Aquí agafem de la taula 14
    
    
    
-- taula 14, creo columna amb parcela
alter table [SCHEMA_NAME].edificis14 
	add column if not exists parcela character varying;
update [SCHEMA_NAME].edificis14 set parcela = cat;
update [SCHEMA_NAME].edificis14 set 
	parcela = substring(parcela from 31 for 14);

-- taula 14, creo columna amb bloc
alter table [SCHEMA_NAME].edificis14 
	add column if not exists bloc character varying;
update [SCHEMA_NAME].edificis14 set bloc = cat;
update [SCHEMA_NAME].edificis14 set 
	bloc = substring(bloc from 59 for 4);	

-- taula 14, creo columna amb escala
alter table [SCHEMA_NAME].edificis14 
	add column if not exists escala character varying;
update [SCHEMA_NAME].edificis14 set escala = cat;
update [SCHEMA_NAME].edificis14 set 
	escala = substring(escala from 63 for 2);
	
-- taula 14, creo columna amb planta
alter table [SCHEMA_NAME].edificis14 
	add column if not exists planta character varying;
update [SCHEMA_NAME].edificis14 set planta = cat;
update [SCHEMA_NAME].edificis14 set 
	planta = substring(planta from 65 for 3);
	
	
-- taula 14, creo columna amb porta
alter table [SCHEMA_NAME].edificis14 
	add column if not exists porta character varying;
update [SCHEMA_NAME].edificis14 set porta = cat;
update [SCHEMA_NAME].edificis14 set 
	porta = substring(porta from 68 for 3);

-- edificis 14, poso a planta 0 totes les referències de planta que no siguin nombres
UPDATE [SCHEMA_NAME].edificis14
SET planta = '0  '
WHERE planta IN ('PR ','PB ','OD ','S3 ','SA ','SOT','SC ','PC ', 'OP ', 'SM ', 'SO ', 'UE ', 'BJ ', 'TR ', 'PK ', 'OM ', 'SS ', 'AT ', 'ST ','S2 ', 'S1 ', 'AP ', 'PT', 'PL', 
'RS', 'PTA', 'S0 ', 'PP ', 'PIS', 'OR ', 'OL ', 'MU ', 'LC ', 'IS ', 'EX ', 'ENT', 'EN ', 'CO ', 'BX ', 'BE ', 'AL ', 'ES ', 'CC ','MUN','CA ','DX ', '-  ');
ALTER TABLE [SCHEMA_NAME].edificis14 ALTER COLUMN planta SET DATA TYPE integer 
USING NULLIF(TRIM(planta), '')::integer;


-- edificis 14, creo columna amb any_reforma
alter table [SCHEMA_NAME].edificis14 
	add column if not exists any_reforma character varying;
update [SCHEMA_NAME].edificis14 set any_reforma = cat;
update [SCHEMA_NAME].edificis14 set 
any_reforma = SUBSTRING(any_reforma FROM 75 FOR 4);
alter table [SCHEMA_NAME].edificis14 alter column any_reforma set data type integer using any_reforma::integer;

--edificis 14, creo columna amb  columna sup_total
alter table [SCHEMA_NAME].edificis14 
	add column if not exists sup_total character varying;
update [SCHEMA_NAME].edificis14 set sup_total = cat;
update [SCHEMA_NAME].edificis14 set 
sup_total = SUBSTRING(sup_total FROM 84 FOR 7);
alter table [SCHEMA_NAME].edificis14 alter column sup_total set data type integer using sup_total::integer;

--edificis 14, creo columna amb columna sup_terrassa
alter table [SCHEMA_NAME].edificis14 
	add column if not exists sup_terrassa character varying;
update [SCHEMA_NAME].edificis14 set sup_terrassa = cat;
update [SCHEMA_NAME].edificis14 set 
sup_terrassa = SUBSTRING(sup_terrassa FROM 91 FOR 7);
alter table [SCHEMA_NAME].edificis14 alter column sup_terrassa set data type integer using sup_terrassa::integer;

-- edificis 14, fem la diferència entre sup_total i superfície terrassa i la guardem a sup_calef
alter table [SCHEMA_NAME].edificis14 
	add column if not exists sup_calef character varying;
update [SCHEMA_NAME].edificis14 set sup_calef = sup_total-sup_terrassa;
alter table [SCHEMA_NAME].edificis14 alter column sup_calef set data type integer using sup_calef::integer;

-- edificis 14, creem columna amb el codi dgc per saber ús
alter table [SCHEMA_NAME].edificis14 
	add column if not exists codi_dgc character varying;
update [SCHEMA_NAME].edificis14 set codi_dgc = cat;
update [SCHEMA_NAME].edificis14 set 
codi_dgc = SUBSTRING(codi_dgc FROM 71 FOR 3);

-- edificis 14, definim quins usos son climatitzables
alter table [SCHEMA_NAME].edificis14 
	add column if not exists clima character varying;
update [SCHEMA_NAME].edificis14 set clima = diccionari.usos_cadastre.clima
from diccionari.usos_cadastre
where [SCHEMA_NAME].edificis14.codi_dgc = diccionari.usos_cadastre.codi_dgc;

-- edificis 14, definim la superficie climatitzable
alter table [SCHEMA_NAME].edificis14
	add column if not exists superficie_clima integer;
	update [SCHEMA_NAME].edificis14 as e14
set superficie_clima = CASE
		when e14.clima = 'no' then 0
		when e14.clima = 'si' then e14.sup_calef
end;

-- edificis 14, passem el codi_dgc a un text que ens permet agrupar per úsos (residencial, terciari, industrial, exterior ...)
alter table [SCHEMA_NAME].edificis14 
	add column if not exists grup character varying;
update [SCHEMA_NAME].edificis14 set grup =  diccionari.usos_cadastre.grup
from diccionari.usos_cadastre
where [SCHEMA_NAME].edificis14.codi_dgc = diccionari.usos_cadastre.codi_dgc;

-- edificis 14, agafem la planta més alta de cada parcela i la posem a la taula edificis_municipis
alter table [SCHEMA_NAME].edificis_municipis
	add column if not exists plantes integer;
update [SCHEMA_NAME].edificis_municipis as e_mun
set plantes = (
	select max(planta)
	from [SCHEMA_NAME].edificis14 as e14
	where e_mun.reference = e14.parcela
);


-- edificis_municipis, definim la tipologia dels habitatges
alter table [SCHEMA_NAME].edificis_municipis
	add column if not exists tipus_hab character varying;

update [SCHEMA_NAME].edificis_municipis as e_mun
set tipus_hab =
	CASE
		when e_mun."numberOfDwellings" = 1 then 'ResUnifamilar' --unifamiliar
		when e_mun."numberOfDwellings" > 1 and e_mun.plantes <3 then 'ResPlurifamBaix'
		when e_mun."numberOfDwellings"  > 1 and e_mun.plantes >2 then 'ResPlurifamAlt'
		else 'altres'
	end;
	
-----------------------------------------------------------------------------------------------------------------------------


-- 

-----------------------------------------------------------------------------------------------------------------------------


-- -- edificis 14, amb la tipologia ja defifinida, la traslladem a cada vivenda 
alter table [SCHEMA_NAME].edificis14
	add column if not exists tipus character varying;
update [SCHEMA_NAME].edificis14 as e14
set tipus = 
		CASE 
			when e14.grup = 'residencial' 	then ( 
											select tipus_hab
											from [SCHEMA_NAME].edificis_municipis as e_mun
											where  e14.parcela = e_mun.reference 
											LIMIT 1)
			when e14.grup = 'terciari' then 'GT01_SecSchool'
end;

-- Actualitzo 'superficie_clima' segons valors 'tipus' per definir la superfície climatitzada del total de edifici.
UPDATE [SCHEMA_NAME].edificis14 AS e14
SET superficie_clima = CASE
    WHEN e14.tipus = 'ResUnifamilar' THEN e14.superficie_clima / 1.625
    WHEN e14.tipus = 'ResPlurifamBaix' THEN e14.superficie_clima / 1.68
    WHEN e14.tipus = 'ResPlurifamAlt' THEN e14.superficie_clima / 1.68
	when e14.tipus = 'GT01_SecSchool' then e14.superficie_clima / 1.68
    WHEN e14.tipus = 'altres' THEN e14.superficie_clima
END;


	
	
-- edificis 13, canvio el format de l'any de construcció i el copio a la taula 14
UPDATE [SCHEMA_NAME].edificis13
SET any_const = NULL
WHERE any_const = '';

ALTER TABLE [SCHEMA_NAME].edificis13
ALTER COLUMN any_const TYPE INTEGER USING any_const::INTEGER;

alter table [SCHEMA_NAME].edificis14
	add column if not exists any_const integer;
update [SCHEMA_NAME].edificis14 as e14
set any_const = (
	select avg(any_const)
	from [SCHEMA_NAME].edificis13 as e13
	where  e14.parcela = e13.parcela
);
	
-- edificis14, creo una columna amb l'any de referència, el més gran entre el de construcció i el de reforma
alter table [SCHEMA_NAME].edificis14
	add column if not exists any_ref integer;
update [SCHEMA_NAME].edificis14 as e14
set any_ref = greatest(e14.any_const, e14.any_reforma);


alter table [SCHEMA_NAME].edificis14
	add column if not exists codi_any character varying;
	update [SCHEMA_NAME].edificis14 as e14
set codi_any =
	case 
		when e14.any_ref < 1941 then '40' 			--< 40	
		when e14.any_ref > 1940 and e14.any_ref < 1961 then '41_60' --41 - 60 
		when e14.any_ref > 1960 and e14.any_ref < 1981 then '61_80' --61 - 80	
		when e14.any_ref > 1980 and e14.any_ref < 2008 then 'NBECT79' --81 - 07	
		when e14.any_ref > 2007 and e14.any_ref < 2015 then 'CTE2006' --08 - 13	
		when e14.any_ref > 2014 and e14.any_ref < 2021 then 'CTE2013' --14 - 19	
		when e14.any_ref > 2020 then 'CTE2019' 			--> 20  	
	end;	    

-- edificis14, classifico segons normativa de construcció en cas de rehabilitació
alter table [SCHEMA_NAME].edificis14
	add column if not exists codi_any_rehab character varying;
	update [SCHEMA_NAME].edificis14 as e14
set codi_any_rehab =
	case 
		when e14.any_ref < 1941 then 'CTE2013' 			--< 40	
		when e14.any_ref > 1940 and e14.any_ref < 1961 then 'CTE2013' --41 - 60 
		when e14.any_ref > 1960 and e14.any_ref < 1981 then 'CTE2013' --61 - 80	
		when e14.any_ref > 1980 and e14.any_ref < 2008 then 'CTE2013' --81 - 07	
		when e14.any_ref > 2007 and e14.any_ref < 2015 then 'CTE2013' --08 - 13	
		when e14.any_ref > 2014 and e14.any_ref < 2021 then 'CTE2013' --14 - 19	
		when e14.any_ref > 2020 then 'CTE2019' 			--> 20  	
	end;	   	
		
-- incorporo el codi d'idescat a la taula edificis_municipis. Cal tenir la capa Municipis del Cartogràfi carregada
alter table diccionari."Municipis" alter column "CODIMUNI" type integer using "CODIMUNI"::integer;
alter table [SCHEMA_NAME].edificis_municipis
	add column if not exists codi_idescat integer;
update [SCHEMA_NAME].edificis_municipis as e_mun set codi_idescat = mun."CODIMUNI"
from diccionari."Municipis" as mun
where ST_Within(e_mun.geom, mun.geom);

-- incorporo la zona climàtica del municipi
alter table [SCHEMA_NAME].edificis_municipis alter column codi_idescat type integer using codi_idescat::integer;
alter table [SCHEMA_NAME].edificis_municipis
	add column if not exists zona_clima character varying;
update [SCHEMA_NAME].edificis_municipis as e_mun 
set zona_clima = mzc.zona_climatica
from diccionari.municipis_zones_climatiques as mzc
where e_mun.codi_idescat = mzc.codi_idescat ;

-- incorporo la zona climàtica a la vivenda
alter table [SCHEMA_NAME].edificis14
	add column if not exists zona_clima character varying;
	update [SCHEMA_NAME].edificis14 as e14
set zona_clima = (
	select zona_clima
	from [SCHEMA_NAME].edificis_municipis as e_mun
	where  e14.parcela = e_mun.reference
);

-- incorporo la ocupació a cada "vivenda". Provisionalment deixo 1 a esperes de definir-ho.
alter table [SCHEMA_NAME].edificis14
	add column if not exists perfil character varying;
	update [SCHEMA_NAME].edificis14 as e14
set perfil = 
	CASE
		when e14.tipus = 'ResPlurifamBaix' then 'Residencial'
		when e14.tipus = 'ResUnifamilar' then 'Residencial'
		when e14.tipus = 'ResPlurifamAlt' then 'Residencial'
		when e14.tipus = 'GT01_SecSchool' then 'Terciari'
		else 'altres'
end;	

-- a edificis14 tenim tipus, codi_any i zona_clima, creem una columna amb els 3 elements concatenats
alter table [SCHEMA_NAME].edificis14
	add column if not exists id_clima character varying;
	update [SCHEMA_NAME].edificis14 as e14
set id_clima =
	concat(tipus,'_',zona_clima,'_',perfil,'_',codi_any)
;	

-- a edificis14 tenim tipus, codi_any i zona_clima, creem una columna amb els 3 elements concatenats
alter table [SCHEMA_NAME].edificis14
	add column if not exists id_clima_rehab character varying;
	update [SCHEMA_NAME].edificis14 as e14
set id_clima_rehab =
	concat(tipus,'_',zona_clima,'_',perfil,'_',codi_any_rehab)
;	

-- EN AQUEST PUNT JA ES GENERARIA EL GEOJSON PER ENVIAR AL POSTPROCESSAT

-- calculem la demanda de calor [kWh/any] de cada vivenda o espai 
alter table [SCHEMA_NAME].edificis14
	add column if not exists demanda_calor double precision;
	update [SCHEMA_NAME].edificis14 as e14
set demanda_calor = CASE
		when e14.clima = 'no' then 0
		when e14.clima = 'si' then e14.superficie_clima *(
	select "c3: heating demand [kwh/m2]"
	from diccionari.diccionari_carregues_clima as dic_car
	where  e14.id_clima = dic_car.codi
)
end;

-- calculem la demanda de calor [kWh/any] de cada vivenda o espai en cas de rehablitarlo
alter table [SCHEMA_NAME].edificis14
	add column if not exists demanda_calor_rehab double precision;
	update [SCHEMA_NAME].edificis14 as e14
set demanda_calor_rehab = CASE
		when e14.clima = 'no' then 0
		when e14.clima = 'si' then e14.superficie_clima *(
	select "c3: heating demand [kwh/m2]"
	from diccionari.diccionari_carregues_clima as dic_car
	where  e14.id_clima_rehab = dic_car.codi
)
end;

-- calculem la demanda de fred [kWh/any] de cada vivenda o espai 
alter table [SCHEMA_NAME].edificis14
	add column if not exists demanda_fred double precision;
	update [SCHEMA_NAME].edificis14 as e14
set demanda_fred = CASE
		when e14.clima = 'no' then 0
		when e14.clima = 'si' then e14.superficie_clima *(
	select "c4: cooling demand [kwh/m2]"
	from diccionari.diccionari_carregues_clima as dic_car
	where  e14.id_clima = dic_car.codi
)
end;

-- calculem la demanda de fred [kWh/any] de cada vivenda o espai  en cas de rehabilitació
alter table [SCHEMA_NAME].edificis14
	add column if not exists demanda_fred_rehab double precision;
	update [SCHEMA_NAME].edificis14 as e14
set demanda_fred_rehab = CASE
		when e14.clima = 'no' then 0
		when e14.clima = 'si' then e14.superficie_clima *(
	select "c4: cooling demand [kwh/m2]"
	from diccionari.diccionari_carregues_clima as dic_car
	where  e14.id_clima_rehab = dic_car.codi
)
end;

-- calculem la carrega calor [kW] de cada vivenda o espai 
alter table [SCHEMA_NAME].edificis14
	add column if not exists carrega_calor double precision;
	update [SCHEMA_NAME].edificis14 as e14
set carrega_calor = CASE
		when e14.clima = 'no' then 0
		when e14.clima = 'si' then e14.superficie_clima *(
	select  "c7: designday heating peak load [w/m2]"
	from diccionari.diccionari_carregues_clima as dic_car
	where  e14.id_clima = dic_car.codi
)
end;

-- calculem la carrega calor [kW] de cada vivenda o espai un cop rehabilitat
alter table [SCHEMA_NAME].edificis14
	add column if not exists carrega_calor_rehab double precision;
	update [SCHEMA_NAME].edificis14 as e14
set carrega_calor_rehab = CASE
		when e14.clima = 'no' then 0
		when e14.clima = 'si' then e14.superficie_clima *(
	select "c7: designday heating peak load [w/m2]"
	from diccionari.diccionari_carregues_clima as dic_car
	where  e14.id_clima_rehab = dic_car.codi
)
end;

-- calculem la carrega fred [kW] de cada vivenda o espai 
alter table [SCHEMA_NAME].edificis14
	add column if not exists carrega_fred double precision;
	update [SCHEMA_NAME].edificis14 as e14
set carrega_fred = CASE
		when e14.clima = 'no' then 0
		when e14.clima = 'si' then e14.superficie_clima *(
	select "c8: designday total cooling peak load [w/m2]"
	from diccionari.diccionari_carregues_clima as dic_car
	where  e14.id_clima = dic_car.codi
)
end;

-- calculem la carrega fred [kW] de cada vivenda o espai un cop rehabilitat
alter table [SCHEMA_NAME].edificis14
	add column if not exists carrega_fred_rehab double precision;
	update [SCHEMA_NAME].edificis14 as e14
set carrega_fred_rehab = CASE
		when e14.clima = 'no' then 0
		when e14.clima = 'si' then e14.superficie_clima *(
	select "c8: designday total cooling peak load [w/m2]"
	from diccionari.diccionari_carregues_clima as dic_car
	where  e14.id_clima_rehab = dic_car.codi
)
end;



-- passem la demanda de calor [kWh/any] a l'edifici en conjunt. Inicialment no apliquem simultaneitat
alter table [SCHEMA_NAME].edificis_municipis
	add column if not exists demanda_calor double precision;
update [SCHEMA_NAME].edificis_municipis as e_mun
set demanda_calor = (
	select sum(demanda_calor)
	from [SCHEMA_NAME].edificis14 as e14
	where e_mun.reference = e14.parcela
);

-- passem la demanda de calor [kWh/any] a l'edifici en conjunt en cas de rehabilitació. Inicialment no apliquem simultaneitat
alter table [SCHEMA_NAME].edificis_municipis
	add column if not exists demanda_calor_rehab double precision;
update [SCHEMA_NAME].edificis_municipis as e_mun
set demanda_calor_rehab = (
	select sum(demanda_calor_rehab)
	from [SCHEMA_NAME].edificis14 as e14
	where e_mun.reference = e14.parcela
);

-- passem la demanda de fred [kWh/any] a l'edifici en conjunt. Inicialment no apliquem simultaneitat
alter table [SCHEMA_NAME].edificis_municipis
	add column if not exists demanda_fred double precision;
update [SCHEMA_NAME].edificis_municipis as e_mun
set demanda_fred = (
	select sum(demanda_fred)
	from [SCHEMA_NAME].edificis14 as e14
	where e_mun.reference = e14.parcela
);

-- passem la demanda de fred [kWh/any] a l'edifici en conjunt en cas de rehabilitació. Inicialment no apliquem simultaneitat
alter table [SCHEMA_NAME].edificis_municipis
	add column if not exists demanda_fred_rehab double precision;
update [SCHEMA_NAME].edificis_municipis as e_mun
set demanda_fred_rehab = (
	select sum(demanda_fred_rehab)
	from [SCHEMA_NAME].edificis14 as e14
	where e_mun.reference = e14.parcela
);

-- passem la càrrega de calor [kW] p a l'edifici en conjunt. Inicialment no apliquem simultaneitat
alter table [SCHEMA_NAME].edificis_municipis
	add column if not exists carrega_calor double precision;
update [SCHEMA_NAME].edificis_municipis as e_mun
set carrega_calor = 0.001*nullif((
	select sum(carrega_calor)
	from [SCHEMA_NAME].edificis14 as e14
	where e_mun.reference = e14.parcela),0
);

-- potencia calefacció i ACS [kW]

alter table [SCHEMA_NAME].edificis_municipis
	add column if not exists potencia_calor double precision;
update [SCHEMA_NAME].edificis_municipis as e_mun
set potencia_calor = CASE
	when e_mun.carrega_calor < 12 then 12
	else e_mun.carrega_calor
end;


-- passem la càrrega de calor [kW] p a l'edifici rehabilitat en conjunt. Inicialment no apliquem simultaneitat
alter table [SCHEMA_NAME].edificis_municipis
	add column if not exists carrega_calor_rehab double precision;
update [SCHEMA_NAME].edificis_municipis as e_mun
set carrega_calor_rehab = 0.001*nullif((
	select sum(carrega_calor_rehab)
	from [SCHEMA_NAME].edificis14 as e14
	where e_mun.reference = e14.parcela),0
);

-- potencia fred i ACS [kW]

alter table [SCHEMA_NAME].edificis_municipis
	add column if not exists potencia_fred double precision;
update [SCHEMA_NAME].edificis_municipis as e_mun
set potencia_fred = CASE
	when e_mun.carrega_fred < 3 then 3
	else e_mun.carrega_fred
end;

-- passem la càrrega de fred [kW] a l'edifici en conjunt. Inicialment no apliquem simultaneitat
alter table [SCHEMA_NAME].edificis_municipis
	add column if not exists carrega_fred double precision;
update [SCHEMA_NAME].edificis_municipis as e_mun
set carrega_fred = 0.001*nullif((
	select sum(carrega_fred)
	from [SCHEMA_NAME].edificis14 as e14
	where e_mun.reference = e14.parcela),0
);

-- passem la càrrega de fred [kW] p a l'edifici rehabilitat en conjunt. Inicialment no apliquem simultaneitat
alter table [SCHEMA_NAME].edificis_municipis
	add column if not exists carrega_fred_rehab double precision;
update [SCHEMA_NAME].edificis_municipis as e_mun
set carrega_fred_rehab = 0.001*nullif((
	select sum(carrega_fred_rehab)
	from [SCHEMA_NAME].edificis14 as e14
	where e_mun.reference = e14.parcela),0
);

-- passem la superfície climatitzable [m2] a l'edifici en conjunt. 
alter table [SCHEMA_NAME].edificis_municipis
	add column if not exists superficie_clima integer;
update [SCHEMA_NAME].edificis_municipis as e_mun
set superficie_clima = (
	select sum(superficie_clima)
	from [SCHEMA_NAME].edificis14 as e14
	where e_mun.reference = e14.parcela
);

-- generem el rati [W/m2] de calor per edifici
alter table [SCHEMA_NAME].edificis_municipis
	add column if not exists rati_calor integer;
update [SCHEMA_NAME].edificis_municipis as e_mun
set rati_calor = 
	(carrega_calor*1000)/nullif(superficie_clima,0)
;

-- generem el rati [W/m2] de calor per edifici
alter table [SCHEMA_NAME].edificis_municipis
	add column if not exists rati_fred integer;
update [SCHEMA_NAME].edificis_municipis as e_mun
set rati_fred = 
	(carrega_fred*1000)/nullif(superficie_clima,0)
;

-- generem el rati [W/m2] de calor per edifici rehabilitat
alter table [SCHEMA_NAME].edificis_municipis
	add column if not exists rati_calor_rehab integer;
update [SCHEMA_NAME].edificis_municipis as e_mun
set rati_calor_rehab = 
	(carrega_calor_rehab*1000)/nullif(superficie_clima,0)
;

-- generem el rati [W/m2] de calor per edifici rehabilitat
alter table [SCHEMA_NAME].edificis_municipis
	add column if not exists rati_fred_rehab integer;
update [SCHEMA_NAME].edificis_municipis as e_mun
set rati_fred_rehab = 
	(carrega_fred_rehab*1000)/nullif(superficie_clima,0)
;


-- Add column if not exists
ALTER TABLE [SCHEMA_NAME].edificis_municipis
	ADD COLUMN IF NOT EXISTS id_clima CHARACTER VARYING;

-- Update the 'id_clima' column with the majority cluster code
UPDATE [SCHEMA_NAME].edificis_municipis AS e_mun
SET id_clima = (
	SELECT mode() WITHIN GROUP (ORDER BY id_clima)
	FROM [SCHEMA_NAME].edificis14 AS e14
	WHERE e_mun.reference = e14.parcela
);

-- Add column if not exists
ALTER TABLE [SCHEMA_NAME].edificis_municipis
	ADD COLUMN IF NOT EXISTS codi_any CHARACTER VARYING;

-- Update the 'codi_any' column with the majority cluster code
UPDATE [SCHEMA_NAME].edificis_municipis AS e_mun
SET codi_any = (
	SELECT mode() WITHIN GROUP (ORDER BY codi_any)
	FROM [SCHEMA_NAME].edificis14 AS e14
	WHERE e_mun.reference = e14.parcela
);
