-- EagleUnion_Essex_XP2
-- Author: HSbF6HSO3F
-- DateCreated: 2023/10/31 16:33:01
--------------------------------------------------------------
--Units_XP2
INSERT INTO Units_XP2
		(UnitType,				ResourceCost,	ResourceMaintenanceType,ResourceMaintenanceAmount)
VALUES	('UNIT_ESSEX_CLASS',	1,				'RESOURCE_OIL',			1),
		('UNIT_F2H',			1,				'RESOURCE_ALUMINUM',	1);

--Extra Agenda
INSERT INTO ExclusiveAgendas
		(AgendaOne,		AgendaTwo)
VALUES	('AGENDA_TF58','AGENDA_GREAT_WHITE_FLEET');