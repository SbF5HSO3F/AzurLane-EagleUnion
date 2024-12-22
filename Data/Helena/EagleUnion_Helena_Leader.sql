-- EagleUnion_Leader_Helena
-- Author: HSbF6HSO3F
-- DateCreated: 2024/4/4 22:28:46
--------------------------------------------------------------
CREATE TEMPORARY TABLE temp_Helena_Table (
     DistrictType TEXT,
	 YieldType TEXT,
	 Description TEXT
);

INSERT INTO temp_Helena_Table
		(DistrictType,				YieldType,			Description)
VALUES	('DISTRICT_CAMPUS',			'YIELD_SCIENCE',	'LOC_Kula_Science'),
		('DISTRICT_INDUSTRIAL_ZONE','YIELD_PRODUCTION',	'LOC_Kula_Production'),
		('DISTRICT_HOLY_SITE',		'YIELD_FAITH',		'LOC_Kula_Faith'),
		('DISTRICT_THEATER',		'YIELD_CULTURE',	'LOC_Kula_Culture'),
		('DISTRICT_HARBOR',			'YIELD_GOLD',		'LOC_Kula_Gold'),
		('DISTRICT_COMMERCIAL_HUB',	'YIELD_GOLD',		'LOC_Kula_Gold');

INSERT INTO TraitModifiers
		(TraitType,							    ModifierId)
SELECT	'TRAIT_LEADER_THE_WONDER_OF_KULA_GULF',	'HELENA_COAST_' || DistrictType || '_STANDARD_ADJACENCY'
FROM temp_Helena_Table;

INSERT INTO Modifiers
		(ModifierId,										        ModifierType)
SELECT	'HELENA_COAST_' || DistrictType || '_STANDARD_ADJACENCY',   'MODIFIER_PLAYER_CITIES_TERRAIN_ADJACENCY'
FROM temp_Helena_Table;

INSERT INTO ModifierArguments
		(ModifierId,										        Name,			Value)
SELECT	'HELENA_COAST_' || DistrictType || '_STANDARD_ADJACENCY',   'Amount',		1
FROM temp_Helena_Table
UNION
SELECT  'HELENA_COAST_' || DistrictType || '_STANDARD_ADJACENCY',   'Description',	Description
FROM temp_Helena_Table
UNION
SELECT  'HELENA_COAST_' || DistrictType || '_STANDARD_ADJACENCY',   'DistrictType',	DistrictType
FROM temp_Helena_Table
UNION
SELECT  'HELENA_COAST_' || DistrictType || '_STANDARD_ADJACENCY',   'TerrainType',	'TERRAIN_COAST'
FROM temp_Helena_Table
UNION
SELECT  'HELENA_COAST_' || DistrictType || '_STANDARD_ADJACENCY',   'TilesRequired',1
FROM temp_Helena_Table
UNION
SELECT  'HELENA_COAST_' || DistrictType || '_STANDARD_ADJACENCY',   'YieldType',	YieldType
FROM temp_Helena_Table;

CREATE TEMPORARY TABLE temp_Helena_District_Table (
    ModifierId TEXT,
    DistrictType TEXT
);

INSERT INTO temp_Helena_District_Table
        (ModifierId,                                DistrictType)
SELECT	'HELENA_COAST_CULTURE_' || DistrictType,	DistrictType
FROM Districts WHERE DistrictType NOT IN (SELECT CivUniqueDistrictType FROM DistrictReplaces);

INSERT INTO TraitModifiers
		(TraitType,							    ModifierId)
SELECT	'TRAIT_LEADER_THE_WONDER_OF_KULA_GULF',	ModifierId
FROM temp_Helena_District_Table;

INSERT INTO Modifiers
		(ModifierId,ModifierType)
SELECT	ModifierId, 'MODIFIER_PLAYER_CITIES_TERRAIN_ADJACENCY'
FROM temp_Helena_District_Table;

INSERT INTO ModifierArguments
		(ModifierId,Name,			Value)
SELECT	ModifierId, 'Amount',		1
FROM temp_Helena_District_Table
UNION
SELECT  ModifierId,'Description',	'LOC_Kula_Culture'
FROM temp_Helena_District_Table
UNION
SELECT  ModifierId,'DistrictType',	DistrictType
FROM temp_Helena_District_Table
UNION
SELECT  ModifierId,'TerrainType',	'TERRAIN_COAST'
FROM temp_Helena_District_Table
UNION
SELECT  ModifierId,'TilesRequired', 1
FROM temp_Helena_District_Table
UNION
SELECT  ModifierId,'YieldType',	    'YIELD_CULTURE'
FROM temp_Helena_District_Table;