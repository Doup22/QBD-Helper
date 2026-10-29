-- Queen Black Dragon Helper UI
-- PrettyUI overlay, settings and saved position.

local QBDUI = {}
local PrettyUI = prettyui

if not PrettyUI then
    print("[QBD Helper] ERROR: PrettyUI dependency was not loaded.")
    return nil
end

local PANEL_WIDTH = 340
local WINDOW_CHROME_HEIGHT = 36
local DEFAULT_X, DEFAULT_Y = 30, 150
local WINDOW_TITLE = "Queen Black Dragon Helper"

local LAYOUT = {
    normal = { startY = 38, height = 24, spacing = 29, bottom = 8, alertGap = 9 },
    compact = { startY = 34, height = 21, spacing = 24, bottom = 5, alertGap = 7 }
}

local DEFAULT_COLOUR = {
    default = 0xE0D6BDFF,
    label = 0xBAA373FF,
    accent = 0xF0C766FF,
    windowTitle = 0xD9AB6EFF,
    muted = 0xB8B8B8FF,
    crystal = 0x4CD9FFFF,
    hardened = 0x629741FF,
    danger = 0xFF2E2EFF,
    ready = 0x59FF59FF,
    rowBackground = 0x14120F38,
    alertRow = 0x3D0D0A33,
    divider = 0x997338CC
}

local COLOUR = {}
for name, value in pairs(DEFAULT_COLOUR) do
    COLOUR[name] = value
end

local function rgbaToVector4(rgba)
    local r = math.floor(rgba / 0x1000000) % 0x100
    local g = math.floor(rgba / 0x10000) % 0x100
    local b = math.floor(rgba / 0x100) % 0x100
    local a = rgba % 0x100

    return Vector4.new(r / 255, g / 255, b / 255, a / 255)
end

local DB = {
    posX = "qbd_helper_window_x",
    posY = "qbd_helper_window_y",
    colours = "qbd_helper_colours_enabled",
    compact = "qbd_helper_compact_mode",
    phase = "qbd_helper_show_phase",
    form = "qbd_helper_show_form",
    weakness = "qbd_helper_show_weakness",
    artefact = "qbd_helper_show_artefact",
    souls = "qbd_helper_show_souls",
    timeStop = "qbd_helper_show_timestop",
    mechanic = "qbd_helper_show_mechanic",
    mechanicDuration = "qbd_helper_mechanic_duration_seconds",
    colourDefault = "qbd_helper_colour_default",
    colourLabel = "qbd_helper_colour_label",
    colourAccent = "qbd_helper_colour_accent",
    colourWindowTitle = "qbd_helper_colour_window_title",
    colourCrystal = "qbd_helper_colour_crystal",
    colourHardened = "qbd_helper_colour_hardened",
    colourReady = "qbd_helper_colour_ready",
    colourDanger = "qbd_helper_colour_danger"
}

local settings = {
    coloursEnabled = true,
    compactMode = false,
    showPhase = true,
    showForm = true,
    showWeakness = true,
    showArtefact = true,
    showSouls = true,
    showTimeStop = true,
    showMechanic = true,
    mechanicDurationSeconds = 6
}

local COLOUR_SETTINGS = {
    { key = "default", db = DB.colourDefault, label = "Normal text" },
    { key = "label", db = DB.colourLabel, label = "Row labels" },
    { key = "accent", db = DB.colourAccent, label = "Phase value" },
    { key = "windowTitle", db = DB.colourWindowTitle, label = "Window title" },
    { key = "crystal", db = DB.colourCrystal, label = "Crystal form" },
    { key = "hardened", db = DB.colourHardened, label = "Hardened Carapace" },
    { key = "ready", db = DB.colourReady, label = "Artefact ready" },
    { key = "danger", db = DB.colourDanger, label = "Mechanic alerts" }
}

local ROW_SETTINGS = {
    phase = { field = "showPhase", db = DB.phase },
    form = { field = "showForm", db = DB.form },
    weakness = { field = "showWeakness", db = DB.weakness },
    artefact = { field = "showArtefact", db = DB.artefact },
    souls = { field = "showSouls", db = DB.souls },
    timestop = { field = "showTimeStop", db = DB.timeStop },
    mechanic = { field = "showMechanic", db = DB.mechanic }
}

local PREVIEW_DATA = {
    phase = "3",
    form = "HARDENED CARAPACE",
    weakness = "Magic",
    artefact = "Artefact 3: READY",
    souls = 4,
    timeStop = "ACTIVE",
    mechanic = "FIRE WALL"
}

local gameWindow
local overlayWindow
local gearButton
local settingsWindow
local settingsView
local settingsLayerSubscribed = false
local previewActive = false
local encounterVisible = false
local currentPanelHeight = 290

local rows = {}
local alertDivider
local cache = {
    phase = nil,
    form = nil,
    weakness = nil,
    artefact = nil,
    souls = nil,
    timeStop = nil,
    mechanic = nil
}

local function readBool(key, defaultValue)
    local value = PersistentDB:GetBool(key)
    return value == nil and defaultValue or value
end

local function readInt(key, defaultValue)
    local value = PersistentDB:GetInt(key)
    return value == nil and defaultValue or value
end

local function readColour(key, defaultValue)
    local saved = PersistentDB:GetString(key)
    if not saved then
        return defaultValue
    end

    local value = tonumber(saved, 16)
    if not value or value < 0 or value > 0xFFFFFFFF then
        return defaultValue
    end

    return value
end

local function saveColour(key, value)
    PersistentDB:SetString(key, string.format("%08X", value))
end

local function loadColours()
    for _, option in ipairs(COLOUR_SETTINGS) do
        COLOUR[option.key] = readColour(option.db, DEFAULT_COLOUR[option.key])
    end
end

local function loadSettings()
    loadColours()
    settings.coloursEnabled = readBool(DB.colours, true)
    settings.compactMode = readBool(DB.compact, false)
    settings.showPhase = readBool(DB.phase, true)
    settings.showForm = readBool(DB.form, true)
    settings.showWeakness = readBool(DB.weakness, true)
    settings.showArtefact = readBool(DB.artefact, true)
    settings.showSouls = readBool(DB.souls, true)
    settings.showTimeStop = readBool(DB.timeStop, true)
    settings.showMechanic = readBool(DB.mechanic, true)
    settings.mechanicDurationSeconds = math.max(1, math.min(readInt(DB.mechanicDuration, 6), 10))
end

local function activeLayout()
    return settings.compactMode and LAYOUT.compact or LAYOUT.normal
end

local function clampPosition(x, y)
    if not gameWindow then
        return x, y
    end

    local parentWidth = gameWindow.width or PANEL_WIDTH
    local parentHeight = gameWindow.height or currentPanelHeight
    local maxX = math.max(0, parentWidth - PANEL_WIDTH)
    local maxY = math.max(0, parentHeight - currentPanelHeight)

    return math.max(0, math.min(x, maxX)), math.max(0, math.min(y, maxY))
end

local function getOverlayPosition()
    if not overlayWindow then
        return nil, nil
    end

    if tonumber(overlayWindow.x) and tonumber(overlayWindow.y) then
        return tonumber(overlayWindow.x), tonumber(overlayWindow.y)
    end

    for _, field in ipairs({ "root", "frame", "container", "component" }) do
        local component = overlayWindow[field]
        if component and tonumber(component.x) and tonumber(component.y) then
            return tonumber(component.x), tonumber(component.y)
        end
    end

    return nil, nil
end

local function setOverlayPosition(x, y)
    if not overlayWindow then
        return false
    end

    if overlayWindow.SetPos then
        overlayWindow:SetPos(x, y)
        return true
    end

    for _, field in ipairs({ "root", "frame", "container", "component" }) do
        local component = overlayWindow[field]
        if component and component.SetPos then
            component:SetPos(x, y)
            return true
        end
    end

    return false
end

local function loadPosition()
    local x = PersistentDB:GetInt(DB.posX) or DEFAULT_X
    local y = PersistentDB:GetInt(DB.posY) or DEFAULT_Y
    return clampPosition(x, y)
end

function QBDUI.SavePosition()
    local x, y = getOverlayPosition()
    if not x or not y then
        return
    end

    PersistentDB:SetInt(DB.posX, math.floor(x + 0.5))
    PersistentDB:SetInt(DB.posY, math.floor(y + 0.5))
end

function QBDUI.ResetPosition()
    local x, y = clampPosition(DEFAULT_X, DEFAULT_Y)
    PersistentDB:SetInt(DB.posX, x)
    PersistentDB:SetInt(DB.posY, y)
    setOverlayPosition(x, y)
end

local function setTitleComponentColour(component)
    local componentType = type(component)
    if componentType ~= "table" and componentType ~= "userdata" then
        return false
    end

    local ok, content = pcall(function()
        return component.content
    end)

    if not ok or tostring(content or "") ~= WINDOW_TITLE then
        return false
    end

    return pcall(function()
        component.colour = rgbaToVector4(COLOUR.windowTitle)
    end)
end

local function applyWindowTitleColour()
    if not overlayWindow or type(overlayWindow) ~= "table" then
        return
    end

    for _, component in pairs(overlayWindow) do
        if setTitleComponentColour(component) then
            return
        end

        if type(component) == "table" then
            for _, nested in pairs(component) do
                if setTitleComponentColour(nested) then
                    return
                end
            end
        end
    end
end

local function setOverlayTitle()
    if overlayWindow then
        overlayWindow:SetTitle(WINDOW_TITLE)
        applyWindowTitleColour()
    end
end

local function createText(width, horizontalAlign)
    local text = ui.Text.new(overlayWindow.content)
    text:SetSize(width, LAYOUT.normal.height)
    text.font = id.Font.MUSEO_SANS_15PT_REGULAR
    text.colour = rgbaToVector4(COLOUR.default)
    text.content = ""
    text.clickthrough = true
    text:AlignTo(horizontalAlign or ui.AlignMode.TOPLEFT, ui.AlignMode.CENTRE)
    return text
end

local function createInfoRow(label)
    local background = ui.Rectangle.new(overlayWindow.content)
    background.fill = true
    background.colour = rgbaToVector4(COLOUR.rowBackground)
    background.clickthrough = true

    local labelText = createText(90, ui.AlignMode.TOPLEFT)
    labelText.content = label

    local valueText = createText(204, ui.AlignMode.BOTTOMRIGHT)

    return {
        background = background,
        label = labelText,
        value = valueText,
        alert = false
    }
end

local function createAlertRow()
    local background = ui.Rectangle.new(overlayWindow.content)
    background.fill = true
    background.colour = rgbaToVector4(COLOUR.alertRow)
    background.clickthrough = true

    local text = createText(300, ui.AlignMode.CENTRE)
    text.isShadowed = true

    return {
        background = background,
        value = text,
        alert = true
    }
end

local function setRowHidden(row, hidden)
    if not row then return end
    row.background.hidden = hidden
    if row.label then row.label.hidden = hidden end
    row.value.hidden = hidden
end

local function positionRow(row, y, height)
    row.background:SetPos(12, y - 2)
    row.background:SetSize(316, height + 4)

    if row.alert then
        row.background.colour = rgbaToVector4(COLOUR.alertRow)
        row.value:SetPos(20, y)
        row.value:SetSize(300, height)
        return
    end
    row.background.colour = rgbaToVector4(COLOUR.rowBackground)
    row.label:SetPos(20, y)
    row.label:SetSize(90, height)
    row.value:SetPos(116, y)
    row.value:SetSize(204, height)
end

local function splitArtefact(text)
    local number, status = string.match(tostring(text or ""), "^Artefact%s+(%d+):%s+(.+)$")
    if number then
        return "ARTEFACT " .. number, string.upper(status)
    end
    return "ARTEFACT", tostring(text or "-")
end

local function selectedColour(colour)
    return settings.coloursEnabled and colour or COLOUR.default
end

local function formColour(form)
    if form == "CRYSTAL" then
        return COLOUR.crystal
    elseif form == "HARDENED CARAPACE" then
        return COLOUR.hardened
    end
    return COLOUR.default
end

local function artefactColour(artefact)
    local text = tostring(artefact or "")
    if string.find(text, "READY", 1, true) then
        return COLOUR.ready
    elseif string.find(text, "Inactive", 1, true) then
        return COLOUR.muted
    end
    return COLOUR.default
end

local function applyColours()
    for _, name in ipairs({ "phase", "form", "weakness", "artefact", "souls" }) do
        local row = rows[name]
        if row and row.label then
            row.label.colour = rgbaToVector4(COLOUR.label)
        end
    end

    if rows.phase then rows.phase.value.colour = rgbaToVector4(selectedColour(COLOUR.accent)) end
    if rows.form then rows.form.value.colour = rgbaToVector4(selectedColour(formColour(cache.form))) end
    if rows.weakness then rows.weakness.value.colour = rgbaToVector4(selectedColour(formColour(cache.form))) end
    if rows.artefact then rows.artefact.value.colour = rgbaToVector4(selectedColour(artefactColour(cache.artefact))) end
    if rows.souls then rows.souls.value.colour = rgbaToVector4(COLOUR.default) end
    if rows.timeStop then rows.timeStop.value.colour = rgbaToVector4(selectedColour(COLOUR.danger)) end
    if rows.mechanic then rows.mechanic.value.colour = rgbaToVector4(selectedColour(COLOUR.danger)) end
end

local function refreshColours()
    refreshColours()
end

local function rowIsVisible(name)
    if name == "phase" then
        return settings.showPhase
    elseif name == "form" then
        return settings.showForm
    elseif name == "weakness" then
        return settings.showWeakness and cache.weakness and cache.weakness ~= "-"
    elseif name == "artefact" then
        return settings.showArtefact
    elseif name == "souls" then
        return settings.showSouls and (tonumber(cache.souls) or 0) > 0
    elseif name == "timeStop" then
        return settings.showTimeStop and cache.timeStop == "ACTIVE"
    elseif name == "mechanic" then
        return settings.showMechanic and cache.mechanic and cache.mechanic ~= "-"
    end
    return false
end

local INFO_ROW_ORDER = { "phase", "form", "weakness", "artefact", "souls" }
local ALERT_ROW_ORDER = { "timeStop", "mechanic" }

local function relayoutRows()
    if not overlayWindow then
        return
    end

    local layout = activeLayout()
    local y = layout.startY
    local lastBottom = layout.startY

    for _, name in ipairs(INFO_ROW_ORDER) do
        local row = rows[name]
        local visible = row and rowIsVisible(name)
        setRowHidden(row, not visible)

        if visible then
            positionRow(row, y, layout.height)
            lastBottom = y + layout.height
            y = y + layout.spacing
        end
    end

    local hasAlerts = rowIsVisible("timeStop") or rowIsVisible("mechanic")
    if alertDivider then
        alertDivider.hidden = not hasAlerts
    end

    if hasAlerts then
        local dividerY = y + 1
        alertDivider:SetPos(16, dividerY)
        alertDivider:SetSize(308, 1)
        y = dividerY + layout.alertGap

        for _, name in ipairs(ALERT_ROW_ORDER) do
            local row = rows[name]
            local visible = row and rowIsVisible(name)
            setRowHidden(row, not visible)

            if visible then
                positionRow(row, y, layout.height)
                lastBottom = y + layout.height
                y = y + layout.spacing
            end
        end
    else
        for _, name in ipairs(ALERT_ROW_ORDER) do
            setRowHidden(rows[name], true)
        end
    end

    local contentHeight = math.max(layout.startY + layout.height, lastBottom) + layout.bottom
    currentPanelHeight = WINDOW_CHROME_HEIGHT + contentHeight
    overlayWindow:SetContentHeight(contentHeight)
    overlayWindow:SetSize(PANEL_WIDTH, currentPanelHeight)
end

local function setBoolSetting(field, dbKey, value, refreshColour)
    settings[field] = value
    PersistentDB:SetBool(dbKey, value)

    if refreshColour then
        applyColours()
    end
    relayoutRows()
end

local function setCustomColour(option, value)
    COLOUR[option.key] = value
    saveColour(option.db, value)

    refreshColours()
end

local function resetCustomColours(pickers)
    for _, option in ipairs(COLOUR_SETTINGS) do
        COLOUR[option.key] = DEFAULT_COLOUR[option.key]
        saveColour(option.db, DEFAULT_COLOUR[option.key])

        local picker = pickers and pickers[option.key]
        if picker then
            picker:SetValue(DEFAULT_COLOUR[option.key], false)
        end
    end

    applyWindowTitleColour()
    applyColours()
end

local function buildSettingsContent(host)
    host:AddTitle("QBD Helper Settings")
    host:AddText("Changes are saved immediately and apply to the encounter overlay.")

    host:AddDivider({ marginTop = 8, marginBottom = 8 })
    host:AddTitle("Display")
    host:AddCheckboxButton({
        {
            text = "Use colours",
            value = "coloursEnabled",
            selected = settings.coloursEnabled,
            tooltip = "Use colour coding for forms, artefacts and danger alerts."
        },
        {
            text = "Compact mode",
            value = "compactMode",
            selected = settings.compactMode,
            tooltip = "Reduce row spacing and overall overlay height."
        }
    }, {
        onChange = function(_, _, changedValue, selected)
            if changedValue == "coloursEnabled" then
                setBoolSetting("coloursEnabled", DB.colours, selected, true)
            elseif changedValue == "compactMode" then
                setBoolSetting("compactMode", DB.compact, selected, false)
            end
        end
    })

    host:AddDivider({ marginTop = 8, marginBottom = 8 })
    host:AddTitle("Colours")
    host:AddText("Choose the colours used by the encounter overlay.")

    local colourPickers = {}

    for _, option in ipairs(COLOUR_SETTINGS) do
        local colourOption = option

        host:AddText({
            text = colourOption.label,
            marginTop = 6,
            marginBottom = 2
        })

        colourPickers[colourOption.key] = host:AddColourPicker({
            value = COLOUR[colourOption.key],
            windowTitle = colourOption.label,
            tooltip = "Choose the " .. string.lower(colourOption.label) .. " colour.",
            onChange = function(_, value)
                setCustomColour(colourOption, value)
            end
        })
    end

    host:AddFancyButton("Reset colours to default", function()
        resetCustomColours(colourPickers)
    end, {
        variant = "neutral",
        tooltip = "Restore the original QBD Helper colours."
    })

    host:AddDivider({ marginTop = 8, marginBottom = 8 })
    host:AddTitle("Visible rows")
    host:AddCheckboxButton({
        { text = "Phase", value = "phase", selected = settings.showPhase },
        { text = "Form", value = "form", selected = settings.showForm },
        { text = "Weakness", value = "weakness", selected = settings.showWeakness },
        { text = "Artefact", value = "artefact", selected = settings.showArtefact },
        { text = "Tortured Souls", value = "souls", selected = settings.showSouls },
        { text = "Time Stop", value = "timestop", selected = settings.showTimeStop },
        { text = "Mechanic alerts", value = "mechanic", selected = settings.showMechanic }
    }, {
        onChange = function(_, _, changedValue, selected)
            local rowSetting = ROW_SETTINGS[changedValue]
            if rowSetting then
                setBoolSetting(rowSetting.field, rowSetting.db, selected, false)
            end
        end
    })

    host:AddDivider({ marginTop = 8, marginBottom = 8 })
    host:AddTitle("Mechanic alerts")

    local durationLabel = host:AddText(
        "Alert duration: " .. tostring(settings.mechanicDurationSeconds) .. " seconds"
    )

    host:AddSlider({
        min = 1,
        max = 10,
        value = settings.mechanicDurationSeconds,
        step = 1,
        onChange = function(_, value)
            local seconds = tonumber(value)
            if not seconds then
                return
            end

            seconds = math.max(1, math.min(seconds, 10))
            settings.mechanicDurationSeconds = seconds
            PersistentDB:SetInt(DB.mechanicDuration, seconds)
            durationLabel.content = "Alert duration: " .. tostring(seconds) .. " seconds"
        end
    })

    host:AddDivider({ marginTop = 8, marginBottom = 8 })
    host:AddTitle("Window")
    host:AddCheckboxButton({
        {
            text = "Show overlay preview",
            value = "preview",
            selected = previewActive,
            tooltip = "Show sample encounter data so you can position and configure the overlay anywhere."
        }
    }, {
        onChange = function(_, _, changedValue, selected)
            if changedValue == "preview" then
                QBDUI.SetPreviewEnabled(selected)
            end
        end
    })

    host:AddText("Preview uses sample data only and does not affect the encounter.")
    host:AddFancyButton("Reset window position", function()
        QBDUI.ResetPosition()
    end, {
        variant = "neutral",
        tooltip = "Move the QBD encounter overlay back to its default position."
    })
end

local function mountGlobalSettings(event)
    if settingsView then
        settingsView:Destroy()
        settingsView = nil
    end

    if not event or not event.component then
        return
    end

    local parent = event.component
    settingsView = PrettyUI.SimpleView.new(parent, {
        width = parent.width,
        height = parent.height,
        scrollable = true
    })
    buildSettingsContent(settingsView)
end

local function subscribeSettingsLayer()
    if settingsLayerSubscribed then
        return
    end

    Event.SettingsLayerReady.Subscribe("QBD_Helper_SettingsLayer", mountGlobalSettings)
    settingsLayerSubscribed = true
end

local function openSettingsWindow()
    if settingsWindow then
        settingsWindow:Destroy()
    end

    settingsWindow = PrettyUI.Window.new(gameWindow, {
        title = "QBD Helper Settings",
        x = -210,
        y = -220,
        xAnchor = 0.5,
        yAnchor = 0.5,
        width = 420,
        height = 440,
        resizable = true,
        minWidth = 340,
        minHeight = 300,
        maxWidth = 700,
        maxHeight = 700,
        scrollable = true
    })

    buildSettingsContent(settingsWindow)
    settingsWindow:Show()
end

function QBDUI.Create()
    if overlayWindow then
        return true
    end

    loadSettings()
    subscribeSettingsLayer()

    gameWindow = ui.Interfaces:GetComponent(id.Component.TOPLEVEL_V2__PLUGIN_BUILD_LAYER_TOP)
    if not gameWindow then
        print("[QBD Helper] ERROR: Plugin UI layer not found.")
        return false
    end

    local x, y = loadPosition()
    overlayWindow = PrettyUI.Window.new(gameWindow, {
        title = WINDOW_TITLE,
        x = x,
        y = y,
        width = PANEL_WIDTH,
        height = currentPanelHeight,
        minWidth = PANEL_WIDTH,
        maxWidth = PANEL_WIDTH,
        minHeight = 90,
        maxHeight = 320,
        resizable = false,
        scrollable = false,
        destroyOnClose = false,
        onClose = function()
            QBDUI.SavePosition()
        end
    })

    if not overlayWindow then
        print("[QBD Helper] ERROR: Failed to create PrettyUI encounter window.")
        return false
    end

    applyWindowTitleColour()

    gearButton = PrettyUI.SpriteButton.new(
        overlayWindow.content,
        "SETTINGS",
        openSettingsWindow,
        { x = 303, y = 0, size = 22, tooltip = "QBD Helper settings" }
    )

    rows.phase = createInfoRow("PHASE")
    rows.form = createInfoRow("FORM")
    rows.weakness = createInfoRow("WEAK TO")
    rows.artefact = createInfoRow("ARTEFACT")
    rows.souls = createInfoRow("SOULS")
    rows.timeStop = createAlertRow()
    rows.mechanic = createAlertRow()

    alertDivider = ui.Rectangle.new(overlayWindow.content)
    alertDivider.fill = true
    alertDivider.colour = rgbaToVector4(COLOUR.divider)
    alertDivider.clickthrough = true

    QBDUI.Reset()
    encounterVisible = false
    previewActive = false
    overlayWindow:Close()
    return true
end

function QBDUI.SetVisible(visible)
    encounterVisible = visible == true
    if not overlayWindow then
        return
    end

    if encounterVisible then
        setOverlayTitle()
        overlayWindow:Show()
    elseif previewActive then
        setOverlayTitle()
        QBDUI.Update(PREVIEW_DATA)
        overlayWindow:Show()
    else
        setOverlayTitle()
        overlayWindow:Close()
    end
end

function QBDUI.SetPreviewEnabled(enabled)
    previewActive = enabled == true
    if not overlayWindow then
        return
    end

    if encounterVisible then
        setOverlayTitle()
        overlayWindow:Show()
    elseif previewActive then
        setOverlayTitle()
        QBDUI.Update(PREVIEW_DATA)
        overlayWindow:Show()
    else
        QBDUI.Reset()
        setOverlayTitle()
        overlayWindow:Close()
    end
end

function QBDUI.IsPreviewEnabled()
    return previewActive
end

function QBDUI.GetMechanicDurationTicks()
    local seconds = tonumber(settings.mechanicDurationSeconds) or 6
    return math.max(1, math.floor(seconds / 0.6 + 0.5))
end

function QBDUI.Update(data)
    if not overlayWindow or not data then
        return
    end

    if data.phase ~= cache.phase then
        cache.phase = data.phase
        rows.phase.value.content = tostring(data.phase)
    end

    if data.form ~= cache.form then
        cache.form = data.form
        rows.form.value.content = tostring(data.form)
    end

    if data.weakness ~= cache.weakness then
        cache.weakness = data.weakness
        rows.weakness.value.content = tostring(data.weakness)
    end

    if data.artefact ~= cache.artefact then
        cache.artefact = data.artefact
        local label, value = splitArtefact(data.artefact)
        rows.artefact.label.content = label
        rows.artefact.value.content = value
    end

    if data.souls ~= cache.souls then
        cache.souls = data.souls
        rows.souls.value.content = tostring(data.souls)
    end

    if data.timeStop ~= cache.timeStop then
        cache.timeStop = data.timeStop
        rows.timeStop.value.content = data.timeStop == "ACTIVE" and ">>> TIME STOP ACTIVE <<<" or ""
    end

    if data.mechanic ~= cache.mechanic then
        cache.mechanic = data.mechanic
        rows.mechanic.value.content = (data.mechanic and data.mechanic ~= "-")
            and ">>> " .. tostring(data.mechanic) .. " <<<"
            or ""
    end

    applyColours()
    relayoutRows()
end

function QBDUI.Reset()
    cache = {}

    if not overlayWindow then
        return
    end

    rows.phase.value.content = "-"
    rows.form.value.content = "Normal"
    rows.weakness.value.content = ""
    rows.artefact.label.content = "ARTEFACT 1"
    rows.artefact.value.content = "INACTIVE"
    rows.souls.value.content = ""
    rows.timeStop.value.content = ""
    rows.mechanic.value.content = ""

    applyColours()
    relayoutRows()
end

function QBDUI.Destroy()
    QBDUI.SavePosition()
    previewActive = false
    encounterVisible = false

    if settingsLayerSubscribed then
        Event.SettingsLayerReady.Unsubscribe("QBD_Helper_SettingsLayer")
        settingsLayerSubscribed = false
    end

    if settingsView then
        settingsView:Destroy()
        settingsView = nil
    end

    if settingsWindow then
        settingsWindow:Destroy()
        settingsWindow = nil
    end

    if gearButton then
        gearButton:Destroy()
        gearButton = nil
    end

    if overlayWindow then
        overlayWindow:Destroy()
        overlayWindow = nil
    end

    rows = {}
    alertDivider = nil
end

return QBDUI

