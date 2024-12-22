-- EagleUnion_NewJersey_XP2
-- Author: HSbF6HSO3F
-- DateCreated: 2023/10/31 16:33:38
--------------------------------------------------------------
--Update Units
UPDATE Units
SET StrategicResource='RESOURCE_OIL'
WHERE UnitType='UNIT_IOWA_CLASS';

--Units_XP2
INSERT INTO Units_XP2
		(UnitType,				ResourceCost,	ResourceMaintenanceType,ResourceMaintenanceAmount)
VALUES	('UNIT_IOWA_CLASS',	1,				'RESOURCE_OIL',			1);