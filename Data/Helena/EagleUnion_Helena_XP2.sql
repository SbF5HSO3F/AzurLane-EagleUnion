-- EagleUnion_Helena_XP2
-- Author: HSbF6HSO3F
-- DateCreated: 2023/10/31 16:33:20
--------------------------------------------------------------
--Update Units
UPDATE Units
SET StrategicResource='RESOURCE_OIL'
WHERE UnitType='UNIT_ST_LOUIS_CLASS_LIGHT_CRUISER';

--Units_XP2
INSERT INTO Units_XP2
		(UnitType,								ResourceCost,	ResourceMaintenanceType,ResourceMaintenanceAmount)
VALUES	('UNIT_ST_LOUIS_CLASS_LIGHT_CRUISER',	1,				'RESOURCE_OIL',			1);