-- EagleUnion_Scirpt
-- Author: jjj
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
    if EagleUnionCivTypeMatched(playerID, 'CIVILIZATION_EAGLE_UNION') then
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

Initialize()