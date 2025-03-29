-- Please see the license.html file included with this distribution for
-- attribution and copyright information.
--

-- ==== vehicle_actions (Tab-Level) ====

function onInit()
    if self.getName and self.getName() == "vehicle_actions" then
        update()
        WindowManager.setInitialOrder(self)
    end
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
        desc = sDesc
    }

    if ActionVehicleAttack then
        ActionVehicleAttack.performRoll(draginfo, rActor, rAction)
    else
        ChatManager.SystemMessage("ActionVehicleAttack not defined.")
    end
end

function actionDamage(draginfo)
    local node = self.getDatabaseNode and self.getDatabaseNode() or nil
    if not node then return end

    local rActor = ActorManager.resolveActor(DB.getChild(node, "...."))
    local rAction = ActionDamage.getDamageAction(node, true)

    if ActionVehicleDamage then
        ActionVehicleDamage.performRoll(draginfo, rActor, rAction)
    else
        ChatManager.SystemMessage("ActionVehicleDamage not defined.")
    end
end
