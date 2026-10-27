-- Queen Black Dragon Helper
-- Encounter logic. UI and settings live in ui.lua.

local QBDUI = require("ui")
if not QBDUI or not QBDUI.Create() then
    print("[QBD Helper] ERROR: Failed to initialize UI.")
    return
end

local QBD_BOSS_ID = 15454
local QBD_CRYSTAL_ID = 15506
local TORTURED_SOUL_ID = 15510
local ARENA_SCAN_RANGE = 50
local FORM_DURATION_TICKS = 100
local DEFAULT_MECHANIC_DURATION_TICKS = 10
local MAX_MISSED_TICKS = 5

local QBD_CONFIG_IDS = {
    QBD_BOSS_ID,
    QBD_CRYSTAL_ID,
    15507, -- spirit
    15508, -- passive
    15509  -- sleeping
}

local ARTEFACT_LOC_STATE = {
    [70776] = 0, [70777] = 1, [70778] = 2,
    [70779] = 0, [70780] = 3, [70781] = 4,
    [70782] = 0, [70783] = 5, [70784] = 6,
    [70785] = 0, [70786] = 7, [70787] = 8
}

local ARTEFACT_TEXT = {
    [0] = "Artefact 1: Inactive",
    [1] = "Artefact 1: READY",
    [2] = "Artefact 1: Activated",
    [3] = "Artefact 2: READY",
    [4] = "Artefact 2: Activated",
    [5] = "Artefact 3: READY",
    [6] = "Artefact 3: Activated",
    [7] = "Artefact 4: READY",
    [8] = "Artefact 4: Activated"
}

local FORM_INFO = {
    Crystal = {
        display = "CRYSTAL",
        weakness = "Melee / Ranged / Necromancy"
    },
    ["Hardened Carapace"] = {
        display = "HARDENED CARAPACE",
        weakness = "Magic"
    }
}

local state = {
    qbdDetected = false,
    missedTicks = 0,
    artefact = 0,
    form = "Normal",
    formTicks = 0,
    lastQbdConfigID = nil,
    mechanic = "-",
    mechanicTicks = 0
}

local function lower(value)
    return value and string.lower(tostring(value)) or ""
end

local function findQBD()
    for _, configID in ipairs(QBD_CONFIG_IDS) do
        for _, npc in ipairs(NPCList.ByConfigID(configID)) do
            if npc.isValid then
                return npc
            end
        end
    end

    for _, npc in ipairs(NPCList.ByName("Queen Black Dragon")) do
        if npc.isValid then
            return npc
        end
    end

    return nil
end

local function countTorturedSouls()
    local count = 0
    for _, npc in ipairs(NPCList.ByConfigID(TORTURED_SOUL_ID)) do
        if npc.isValid then
            count = count + 1
        end
    end
    return count
end

local function updateArtefactState()
    if not Player.IsAvailable() then
        return state.artefact
    end

    local player = Player.GetEntity()
    if not player then
        return state.artefact
    end

    local found = false
    local detected = 0

    for _, loc in ipairs(LocList.ByDistance(player.coordGrid, ARENA_SCAN_RANGE, true)) do
        if loc.isValid then
            local artefactState = ARTEFACT_LOC_STATE[loc.configID]
            if artefactState ~= nil then
                found = true
                detected = math.max(detected, artefactState)
            end
        end
    end

    if found then
        state.artefact = detected
    end

    return state.artefact
end

local function getTimeStopState()
    local value = var.VarClient.QBD2_SHOW_TIMESTOP
    if not value or value.value == nil then
        return 0
    end
    return tonumber(value.value) or 0
end

local function setForm(form)
    state.form = form
    state.formTicks = form == "Normal" and 0 or FORM_DURATION_TICKS
end

local function updateFormTimer()
    if state.form == "Normal" then
        return
    end

    state.formTicks = state.formTicks - 1
    if state.formTicks <= 0 then
        setForm("Normal")
    end
end

local function setMechanic(mechanic)
    state.mechanic = mechanic

    if mechanic == "-" then
        state.mechanicTicks = 0
        return
    end

    local ticks = DEFAULT_MECHANIC_DURATION_TICKS
    if QBDUI.GetMechanicDurationTicks then
        ticks = QBDUI.GetMechanicDurationTicks()
    end

    state.mechanicTicks = ticks
end

local function updateMechanicTimer()
    if state.mechanic == "-" then
        return
    end

    state.mechanicTicks = state.mechanicTicks - 1
    if state.mechanicTicks <= 0 then
        setMechanic("-")
    end
end

local function getFormDisplay()
    local info = FORM_INFO[state.form]
    return info and info.display or "Normal"
end

local function getWeaknessText()
    local info = FORM_INFO[state.form]
    return info and info.weakness or "-"
end

local function getPhaseText(artefactState)
    if artefactState <= 1 then return "1" end
    if artefactState <= 3 then return "2" end
    if artefactState <= 5 then return "3" end
    if artefactState <= 7 then return "4" end
    return "Complete"
end

local function getArtefactText(artefactState)
    return ARTEFACT_TEXT[artefactState] or ARTEFACT_TEXT[8]
end

local function onChatMessage(event)
    local message = lower(event.chatMessage)

    if string.find(message, "takes a huge breath", 1, true) then
        setMechanic("FIRE WALL")
        return
    end

    if string.find(message, "gathers her strength to breathe extremely hot flames", 1, true) then
        setMechanic("EXTREME BREATH")
        return
    end

    if string.find(message, "takes on the consistency of crystal", 1, true) then
        setForm("Crystal")
        return
    end

    if string.find(message, "hardens her carapace", 1, true) then
        setForm("Hardened Carapace")
    end
end

local chatSubscribed = false

local function subscribeChat()
    if chatSubscribed then
        return
    end

    Event.ChatMessage.Subscribe("QBD_Helper_Chat", onChatMessage)
    chatSubscribed = true
end

local function unsubscribeChat()
    if not chatSubscribed then
        return
    end

    Event.ChatMessage.Unsubscribe("QBD_Helper_Chat")
    chatSubscribed = false
end

local function onOptionalPermissionChanged(event)
    if not event or event.permissionName ~= "chatAccess" then
        return
    end

    if event.enabled then
        subscribeChat()
        print("[QBD Helper] chatAccess enabled.")
    else
        unsubscribeChat()
        setForm("Normal")
        setMechanic("-")
        print("[QBD Helper] chatAccess disabled.")
    end
end

if Plugin.HasPermission(PluginPermissions.chatAccess) then
    subscribeChat()
else
    print("[QBD Helper] WARNING: chatAccess permission missing.")
end

Event.OptionalPermissionChanged.Subscribe(
    "QBD_Helper_PermissionChanged",
    onOptionalPermissionChanged
)

local function clearEncounterState()
    state.missedTicks = 0
    state.artefact = 0
    state.form = "Normal"
    state.formTicks = 0
    state.lastQbdConfigID = nil
    state.mechanic = "-"
    state.mechanicTicks = 0
end

local function beginEncounter()
    clearEncounterState()
    state.qbdDetected = true
    QBDUI.Reset()
    QBDUI.SetVisible(true)
end

local function endEncounter()
    clearEncounterState()
    state.qbdDetected = false
    QBDUI.Reset()
    QBDUI.SetVisible(false)
end

local function refresh()
    local qbd = findQBD()

    if not qbd then
        if not state.qbdDetected then
            QBDUI.SetVisible(false)
            return
        end

        state.missedTicks = state.missedTicks + 1
        if state.missedTicks <= MAX_MISSED_TICKS then
            return
        end

        endEncounter()
        return
    end

    state.missedTicks = 0
    if not state.qbdDetected then
        beginEncounter()
    end

    QBDUI.SetVisible(true)
    updateFormTimer()
    updateMechanicTimer()

    -- QBD uses a separate NPC config while in Crystal form. Track both
    -- directions so the UI follows the live form instead of waiting on the
    -- fallback timer after she returns to normal.
    if qbd.configID == QBD_CRYSTAL_ID then
        if state.lastQbdConfigID ~= QBD_CRYSTAL_ID then
            setForm("Crystal")
        end
    elseif state.form == "Crystal" and state.lastQbdConfigID == QBD_CRYSTAL_ID then
        setForm("Normal")
    end

    state.lastQbdConfigID = qbd.configID

    local previousArtefactState = state.artefact
    local artefactState = updateArtefactState()

    -- Crystal/Hardened can expire naturally, but they also end when the
    -- current phase finishes. Advancing the artefact state is our reliable
    -- signal that the fight has moved on.
    if artefactState > previousArtefactState and state.form ~= "Normal" then
        setForm("Normal")
    end

    local timeStop = getTimeStopState() == 1 and "ACTIVE" or "Inactive"

    QBDUI.Update({
        phase = getPhaseText(artefactState),
        form = getFormDisplay(),
        weakness = getWeaknessText(),
        artefact = getArtefactText(artefactState),
        souls = countTorturedSouls(),
        timeStop = timeStop,
        mechanic = state.mechanic
    })
end

Event.ServerLogic.Subscribe("QBD_Helper_Update", refresh)
refresh()

function PluginShutdown()
    QBDUI.SavePosition()
    Event.ServerLogic.Unsubscribe("QBD_Helper_Update")

    unsubscribeChat()
    Event.OptionalPermissionChanged.Unsubscribe("QBD_Helper_PermissionChanged")

    QBDUI.Destroy()
end

print("QBD Helper v0.5.14 loaded.")
