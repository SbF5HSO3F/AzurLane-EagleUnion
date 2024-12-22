-- EagleUnion_AllenMSumner_XP2
-- Author: HSbF6HSO3F
-- DateCreated: 2023/10/31 16:32:45
--------------------------------------------------------------
--Update Units
UPDATE Units
SET StrategicResource='RESOURCE_OIL'
WHERE UnitType='UNIT_ALLEN_M_SUMNER_CLASS_DESTROYER';

--Units_XP2
INSERT INTO Units_XP2
		(UnitType,								ResourceCost,	ResourceMaintenanceType,ResourceMaintenanceAmount)
VALUES	('UNIT_ALLEN_M_SUMNER_CLASS_DESTROYER',	1,				'RESOURCE_OIL',			1);