--  Please see the LICENSE.md file included with this distribution for
--  attribution and copyright information.

-- ==== vehicle_actions (Tab-Level) ====

ActionVehicleAttack = {};
ActionVehicleDamage = {};

function onInit()
    if self.getName and self.getName() == "vehicle_actions" then
        update()
        WindowManager.setInitialOrder(self)
    end

    ActionsManager.registerResultHandler("vehicleattack", onVehicleAttack);
    ActionsManager.registerModHandler("vehicledamage", modVehicleDamage);
    ActionsManager.registerResultHandler("vehicledamage", onVehicleDamageResult);
end

function onDrop(x, y, draginfo)
    return WindowManager.handleDropReorder(self, draginfo)
end

function update()
    local node = self.getDatabaseNode and self.getDatabaseNode() or nil
    if not node then return end

    local bReadOnly = WindowManager.getReadOnlyState(node)

    if actions_iedit then
        actions_iedit.setVisible(not bReadOnly)
        if bReadOnly then
            actions_iedit.setValue(0)
        end
    end

    if actions_iadd then
        actions_iadd.setVisible(not bReadOnly)
    end

    if actions then
        actions.update(bReadOnly)
    end
end

-- ==== vehicle_weapons (Weapon Entry Row) ====

function actionAttack(draginfo)
    local node = self.getDatabaseNode and self.getDatabaseNode() or nil
    if not node then return end

    local sName = name and name.getValue() or ""
    local sAttack = attack and attack.getValue() or ""
    local sDamage = damage and damage.getValue() or ""
    local sRange = range and range.getValue() or ""
    local sTraits = traits and traits.getValue() or ""

    if not StringManager.isNumberString(sAttack) then return end

    local nMod = tonumber(sAttack)
    local sAttackType = (sRange or ""):lower()
    local arc = "Forward" -- Placeholder, customize if needed

    if sAttackType ~= "melee" then
        sAttackType = "R"
    else
        sAttackType = "M"
    end

    local sDesc = string.format("[Vehicle ATTACK (%s)] %s (2D%+d)", sAttackType, sName, nMod)

    local bDescNotEmpty = true
    local sStackDesc, nStackMod = ModifierStack.getStack(bDescNotEmpty)

    if nStackMod ~= 0 then
        sDesc = sDesc .. string.format("\n + [MOD] (%+d)", nStackMod)
    end

    local rActor = ActorManager.resolveActor(DB.getChild(node, "...."))
    local rAction = {
        modifier = nMod + nStackMod,
        label = sName,
        arc = arc,
        weaponTraits = sTraits,
        desc = sDesc,
        damage = sDamage
    }

    ActionVehicleAttack.performRoll(draginfo, rActor, rAction)
end

function actionDamage(draginfo)
    local node = self.getDatabaseNode and self.getDatabaseNode() or nil
    if not node then return end

    local rActor = ActorManager.resolveActor(DB.getChild(node, "...."))
    local sName = name and name.getValue() or ""
    local sDamage = damage and damage.getValue() or ""
    local sTraits = traits and traits.getValue() or ""

    local rAction = {
        label = sName,
        damage = sDamage,
        traits = sTraits
    }

    ActionVehicleDamage.performRoll(draginfo, rActor, rAction)
end

function ActionVehicleAttack.performRoll(draginfo, rActor, rAction)
    local rRoll = {}
    rRoll.sType = "vehicleattack"
    rRoll.sDesc = rAction.desc or "[Vehicle Attack]"
    rRoll.aDice = { "d6", "d6" }
    rRoll.nMod = rAction.modifier or 0

    ActionsManager.performAction(draginfo, rActor, rRoll)
end

function ActionVehicleDamage.performRoll(draginfo, rActor, rAction)
    local rRoll = {}
    rRoll.sType = "vehicledamage"
    local sDamage = rAction.damage:upper()

    local bDestructive = sDamage:match("DD$") ~= nil
    local sNum = sDamage:match("^(%d+)[Dd]+$")
    local nDice = tonumber(sNum or "0")

    rRoll.aDice = {}
    for i = 1, nDice do
        table.insert(rRoll.aDice, "d6")
    end

    rRoll.sDamageRaw = sDamage
    rRoll.sLabel = rAction.label or ""
    rRoll.nMod = 0
    rRoll.sTraits = rAction.traits or ""
    rRoll.bDestructive = bDestructive

    local sLabel = string.format("[Vehicle Damage%s] %s%s",
        bDestructive and ": DESTRUCTIVE" or "",
        rRoll.sLabel,
        bDestructive and " (x10) [DESTRUCTIVE]" or "")

    if rRoll.sTraits and rRoll.sTraits ~= "" then
        sLabel = sLabel .. string.format(" [TRAITS: %s]", rRoll.sTraits)
    end

    rRoll.sDesc = sLabel

    ActionsManager.performAction(draginfo, rActor, rRoll)
end

function modVehicleDamage(rSource, rTarget, rRoll)
    -- Placeholder for modifier handling
end

function onVehicleDamageResult(rSource, rTarget, rRoll)
    if rRoll.sDesc:find('%[DESTRUCTIVE%]') then
        rRoll.bDestructive = true
    end

    local nTotal = 0
    local nUnscaledTotal = 0
    local aDieResults = {}
    local aDieScaled = {}

    for _, vDie in ipairs(rRoll.aDice) do
        local nOriginalResult = vDie.result or math.random(1, 6)
        table.insert(aDieResults, tostring(nOriginalResult))
        nUnscaledTotal = nUnscaledTotal + nOriginalResult

        local nScaled = rRoll.bDestructive and (nOriginalResult * 10) or nOriginalResult
        vDie.result = nScaled
        vDie.value = nil

        table.insert(aDieScaled, tostring(nScaled))
        nTotal = nTotal + nScaled
    end

    local rMessage = ActionsManager.createActionMessage(rSource, rRoll)
    rMessage.text = string.format("%s [TYPE: kinetic (%dd6=%d)] = %d [%dd6 = %s]", rRoll.sDesc, #rRoll.aDice, nUnscaledTotal, nTotal, #rRoll.aDice, table.concat(aDieResults, ", "))

    Comm.deliverChatMessage(rMessage)
end

function onVehicleAttack(rSource, rTarget, rRoll)
    local rMessage = ActionsManager.createActionMessage(rSource, rRoll)
    Comm.deliverChatMessage(rMessage)
end
