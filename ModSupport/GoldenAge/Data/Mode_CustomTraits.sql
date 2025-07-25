-- Mode_CustomTraits
-- Author: HSbF6HSO3F
-- DateCreated: 2025/5/26 11:05:46
--------------------------------------------------------------
INSERT INTO Types
	(Type,												Kind)
VALUES
	('GOLDEN_CIVILIZATION_EAGLE_UNION_CUSTOM_FEATURES',	'KIND_TRAIT');

INSERT INTO Traits
	(TraitType,											Name,															Description)
VALUES
	('GOLDEN_CIVILIZATION_EAGLE_UNION_CUSTOM_FEATURES', 'LOC_GOLDEN_CIVILIZATION_EAGLE_UNION_CUSTOM_FEATURES_NAME', 	'LOC_GOLDEN_CIVILIZATION_EAGLE_UNION_CUSTOM_FEATURES_DESCRIPTION');

INSERT INTO CivilizationTraits
	(CivilizationType,				TraitType)
VALUES
	('CIVILIZATION_EAGLE_UNION',	'GOLDEN_CIVILIZATION_EAGLE_UNION_CUSTOM_FEATURES');

INSERT INTO TraitModifiers
	(TraitType,											ModifierId)
VALUES
	('GOLDEN_CIVILIZATION_EAGLE_UNION_CUSTOM_FEATURES',	'GOLDEN_TRAIT_AGRICULTURE_FLOODPLAINS_APPEAL'),
	('GOLDEN_CIVILIZATION_EAGLE_UNION_CUSTOM_FEATURES',	'GOLDEN_TRAIT_AGRICULTURE_FLOODPLAINS_GRASSLAND_APPEAL'),	
	('GOLDEN_CIVILIZATION_EAGLE_UNION_CUSTOM_FEATURES',	'GOLDEN_TRAIT_AGRICULTURE_FLOODPLAINS_PLAINS'),
	('GOLDEN_CIVILIZATION_EAGLE_UNION_CUSTOM_FEATURES',	'GOLDEN_TRAIT_AGRICULTURE_FARM_CULTURE_BOMB'),

	('GOLDEN_CIVILIZATION_EAGLE_UNION_CUSTOM_FEATURES',	'GOLDEN_TRAIT_NORTH_AMERICA_GARRISON_IDENTITY'),
	('GOLDEN_CIVILIZATION_EAGLE_UNION_CUSTOM_FEATURES',	'GOLDEN_TRAIT_NORTH_AMERICA_NO_GARRISON_IDENTITY'),
	('GOLDEN_CIVILIZATION_EAGLE_UNION_CUSTOM_FEATURES',	'GOLDEN_TRAIT_NORTH_AMERICA_FAITH_PURCHASE_CAMPUS');