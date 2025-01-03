-- EagleUnion_XP2
-- Author: HSbF6HSO3F
-- DateCreated: 2023/10/30 12:39:51
--------------------------------------------------------------
--Units_XP2
INSERT INTO Units_XP2
		(UnitType,					ResourceCost,	ResourceMaintenanceType)
VALUES	('UNIT_ENTERPRISE_CLASS',	3,				'RESOURCE_URANIUM');

--District Adjacency
INSERT INTO District_Adjacencies
		(DistrictType,YieldChangeId)
VALUES	('DISTRICT_SANTA_CLARA_VALLEY',	'Government_Production'),
		('DISTRICT_SANTA_CLARA_VALLEY',	'Aqueduct_Production'),
		('DISTRICT_SANTA_CLARA_VALLEY',	'Bath_Production'),
		('DISTRICT_SANTA_CLARA_VALLEY',	'Canal_Production'),
		('DISTRICT_SANTA_CLARA_VALLEY',	'Dam_Production'),
		('DISTRICT_SANTA_CLARA_VALLEY',	'Strategic_Production'),
		('DISTRICT_IVY_LEAGUE',			'Government_Science'),
		('DISTRICT_IVY_LEAGUE',			'Geothermal_Science'),
		('DISTRICT_IVY_LEAGUE',			'Reef_Science');

--Building_TourismBombs_XP2
INSERT INTO Building_TourismBombs_XP2
		(BuildingType,							TourismBombValue)
VALUES	('BUILDING_NEWPORT_NEWS_SHIPBUILDING',	500);