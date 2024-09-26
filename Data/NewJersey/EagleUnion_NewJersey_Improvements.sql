-- EagleUnion_NewJersey_Improvements
-- Author: HSbF6HSO3F
-- 优先级：59
-- DateCreated: 9/21/2023 5:37:08 PM
--------------------------------------------------------------
--农场文化
INSERT INTO Improvement_YieldChanges
        (ImprovementType,           YieldType,      YieldChange)
SELECT  'IMPROVEMENT_FARM',         'YIELD_CULTURE',0
WHERE NOT EXISTS (
    SELECT * FROM Improvement_YieldChanges
    WHERE ImprovementType = 'IMPROVEMENT_FARM' AND YieldType = 'YIELD_CULTURE'
);
--农场金币
INSERT INTO Improvement_YieldChanges
        (ImprovementType,           YieldType,      YieldChange)
SELECT  'IMPROVEMENT_FARM',         'YIELD_GOLD',    0
WHERE NOT EXISTS (
    SELECT * FROM Improvement_YieldChanges
    WHERE ImprovementType = 'IMPROVEMENT_FARM' AND YieldType = 'YIELD_GOLD'
);
--牧场文化
INSERT INTO Improvement_YieldChanges
        (ImprovementType,           YieldType,      YieldChange)
SELECT  'IMPROVEMENT_PASTURE',      'YIELD_CULTURE',0
WHERE NOT EXISTS (
    SELECT * FROM Improvement_YieldChanges
    WHERE ImprovementType = 'IMPROVEMENT_PASTURE' AND YieldType = 'YIELD_CULTURE'
);
--牧场金币
INSERT INTO Improvement_YieldChanges
        (ImprovementType,           YieldType,      YieldChange)
SELECT  'IMPROVEMENT_PASTURE',      'YIELD_GOLD',   0
WHERE NOT EXISTS (
    SELECT * FROM Improvement_YieldChanges
    WHERE ImprovementType = 'IMPROVEMENT_PASTURE' AND YieldType = 'YIELD_GOLD'
);
--营地文化
INSERT INTO Improvement_YieldChanges
        (ImprovementType,           YieldType,      YieldChange)
SELECT  'IMPROVEMENT_CAMP',         'YIELD_CULTURE',0
WHERE NOT EXISTS (
    SELECT * FROM Improvement_YieldChanges
    WHERE ImprovementType = 'IMPROVEMENT_CAMP' AND YieldType = 'YIELD_CULTURE'
);
--营地金币
INSERT INTO Improvement_YieldChanges
        (ImprovementType,           YieldType,      YieldChange)
SELECT  'IMPROVEMENT_CAMP',         'YIELD_GOLD',   0
WHERE NOT EXISTS (
    SELECT * FROM Improvement_YieldChanges
    WHERE ImprovementType = 'IMPROVEMENT_CAMP' AND YieldType = 'YIELD_GOLD'
);
--种植园文化
INSERT INTO Improvement_YieldChanges
        (ImprovementType,           YieldType,      YieldChange)
SELECT  'IMPROVEMENT_PLANTATION',   'YIELD_CULTURE',0
WHERE NOT EXISTS (
    SELECT * FROM Improvement_YieldChanges
    WHERE ImprovementType = 'IMPROVEMENT_PLANTATION' AND YieldType = 'YIELD_CULTURE'
);
--种植园金币
INSERT INTO Improvement_YieldChanges
        (ImprovementType,           YieldType,      YieldChange)
SELECT  'IMPROVEMENT_PLANTATION',   'YIELD_GOLD',   0
WHERE NOT EXISTS (
    SELECT * FROM Improvement_YieldChanges
    WHERE ImprovementType = 'IMPROVEMENT_PLANTATION' AND YieldType = 'YIELD_GOLD'
);