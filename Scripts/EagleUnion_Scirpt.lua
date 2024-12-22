-- EagleUnion_Scirpt
-- Author: HSbF6HSO3F
-- DateCreated: 2024/9/28 15:21:49
--------------------------------------------------------------
--||=======================include========================||--
include('EagleUnion_Core.lua')

--||===================local variables====================||--

local modifier = 'EAGLE_UNION_PER_ACTIVE_GREATPERSON_BUFF'

--||===================Events functions===================||--

--when a great person is activated
function EagleUnionActiveGreatPerson(playerID)
    --check the player civilization
    if EagleCore.CheckCivMatched(playerID, 'CIVILIZATION_EAGLE_UNION') then
        --attach the modifier to the player
        Players[playerID]:AttachModifierByID(modifier)
    end
end

--||======================initialize======================||--

--Initialize
function Initialize()
    -------------------Events-------------------
    Events.UnitGreatPersonActivated.Add(EagleUnionActiveGreatPerson)
    --------------------------------------------
    print('Initial success!')
end

include('EagleUnion_Scirpt_', true)

Initialize()
