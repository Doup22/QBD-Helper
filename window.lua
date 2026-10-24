--------------------------------------------------
-- WINDOW MODULE
--------------------------------------------------

local Window = {}


--------------------------------------------------
-- GAME WINDOW
--------------------------------------------------

local game_window = ui.Interfaces:GetComponent(
    id.Component.TOPLEVEL_V2__PLUGIN_BUILD_LAYER_TOP
)


--------------------------------------------------
-- POPUP WINDOW
--------------------------------------------------

local myGroupBox = ui.GroupBox.new(game_window)

myGroupBox.stylesheetID = id.StyleSheet.DEFAULT
myGroupBox:SetHeaderLayout(0, 0, 0, 0, 0)
myGroupBox:SetSize(200, 140)
myGroupBox:SetPos(0, 0, 0.6, 0.4)

myGroupBox.enabled = true
myGroupBox.clickthrough = false


--------------------------------------------------
-- MOVE HANDLE
--------------------------------------------------

local moveHandle = ui.Button.new(myGroupBox)

moveHandle:SetPos(0, 0)
moveHandle:SetSize(-25, 25, 1.0, 0.0)

moveHandle.label = "Move"
moveHandle.stylesheetID = id.StyleSheet.BUTTON_DEFAULT

moveHandle.sprite.rgba = 0xA8753FFF
moveHandle.text.rgba = 0xF6D48AFF

moveHandle.enabled = true
moveHandle.clickthrough = false


--------------------------------------------------
-- CLOSE BUTTON
--------------------------------------------------

local closeButton = ui.Button.new(myGroupBox)

closeButton:SetPos(-25, 0, 1.0, 0.0)
closeButton:SetSize(25, 25)

closeButton.label = "X"
closeButton.stylesheetID = id.StyleSheet.BUTTON_DEFAULT

closeButton.sprite.rgba = 0x8F3D2FFF
closeButton.text.rgba = 0xF6D48AFF

closeButton.enabled = true
closeButton.clickthrough = false


--------------------------------------------------
-- WINDOW MOVEMENT
--------------------------------------------------

local isDragging = false

local dragMouseStartX = 0
local dragMouseStartY = 0

local dragWindowStartX = 0
local dragWindowStartY = 0


local function startMove(self, x, y)

    if not Mouse.IsAvailable() then
        return true
    end

    local mouseX = Mouse.GetX()
    local mouseY = Mouse.GetY()

    if mouseX == nil or mouseY == nil then
        return true
    end

    isDragging = true

    dragMouseStartX = mouseX
    dragMouseStartY = mouseY

    dragWindowStartX = myGroupBox.x
    dragWindowStartY = myGroupBox.y

    myGroupBox:MoveToFront()

    return true
end


local function updateMove()

    if not isDragging then
        return
    end

    if not moveHandle.isClicked then
        isDragging = false
        return
    end

    if not Mouse.IsAvailable() then
        return
    end

    local mouseX = Mouse.GetX()
    local mouseY = Mouse.GetY()

    if mouseX == nil or mouseY == nil then
        return
    end

    local deltaX =
        mouseX - dragMouseStartX

    local deltaY =
        mouseY - dragMouseStartY

    myGroupBox:SetPos(
        dragWindowStartX + deltaX,
        dragWindowStartY + deltaY
    )
end


local function stopMove(self, x, y)

    isDragging = false

    return true
end


--------------------------------------------------
-- MOVEMENT EVENTS
--------------------------------------------------

moveHandle:Subscribe(
    ui.Hook.ONCLICK,
    "POF_MoveStart",
    startMove
)

moveHandle:Subscribe(
    ui.Hook.ONRELEASE,
    "POF_MoveStop",
    stopMove
)


Event.Logic.Subscribe(
    "POF_MoveUpdate",
    function(logicEvent)
        updateMove()
    end
)


--------------------------------------------------
-- MAIN POPUP TEXT
--------------------------------------------------

local myText = ui.Text.new(myGroupBox)

myText:SetPos(0, 35)
myText:SetSize(0, 50, 1.0, 0.0)

myText.font = id.Font.MUSEO_SANS_15PT_REGULAR
myText:AlignTo(ui.AlignMode.CENTRE)

myText.clickthrough = true
myText.content = ""


--------------------------------------------------
-- AMOUNT LABEL
--------------------------------------------------

local amountLabel = ui.Text.new(myGroupBox)

amountLabel:SetPos(20, 105)
amountLabel:SetSize(62, 20)

amountLabel.font = id.Font.MUSEO_SANS_15PT_REGULAR
amountLabel:AlignTo(ui.AlignMode.CENTRE)

amountLabel.clickthrough = true
amountLabel.content = "Amount:"
amountLabel.rgba = 0xFFFFFFFF


--------------------------------------------------
-- CURRENT AMOUNT
--------------------------------------------------

local amountValueText = ui.Text.new(myGroupBox)

amountValueText:SetPos(82, 105)
amountValueText:SetSize(42, 20)

amountValueText.font = id.Font.MUSEO_SANS_15PT_REGULAR
amountValueText:AlignTo(ui.AlignMode.CENTRE)

amountValueText.clickthrough = true
amountValueText.content = "0"


--------------------------------------------------
-- MAX AMOUNT
--------------------------------------------------

local amountMaxText = ui.Text.new(myGroupBox)

amountMaxText:SetPos(124, 105)
amountMaxText:SetSize(56, 20)

amountMaxText.font = id.Font.MUSEO_SANS_15PT_REGULAR
amountMaxText:AlignTo(ui.AlignMode.CENTRE)

amountMaxText.clickthrough = true
amountMaxText.content = "/ 1000"

-- Maximum is always green
amountMaxText.rgba = 0x55CC55FF


--------------------------------------------------
-- WINDOW STATE
--------------------------------------------------

local popupDismissed = false

myGroupBox.hidden = true


--------------------------------------------------
-- CLOSE WINDOW
--------------------------------------------------

local function closePopup()

    isDragging = false
    popupDismissed = true

    myGroupBox.hidden = true
end


closeButton:Subscribe(
    ui.Hook.ONBUTTONPRESSED,
    closePopup
)


--------------------------------------------------
-- SHOW TROUGH
--------------------------------------------------

function Window:ShowTrough(
    troughNumber,
    foodName,
    amount
)

    if popupDismissed then
        return
    end


    --------------------------------------------------
    -- SHOW WINDOW
    --------------------------------------------------

    myGroupBox.hidden = false

    myText.hidden = false
    amountLabel.hidden = false
    amountValueText.hidden = false
    amountMaxText.hidden = false


    --------------------------------------------------
    -- TROUGH / FOOD TEXT
    --------------------------------------------------

    myText.content =
        "Trough: " ..
        tostring(troughNumber) ..
        "<br><br>" ..
        "Food: " ..
        tostring(foodName)


    --------------------------------------------------
    -- AMOUNT VALUE
    --------------------------------------------------

    amountValueText.content =
        tostring(amount)


    --------------------------------------------------
    -- AMOUNT COLOR
    --------------------------------------------------

    if amount > 500 then

        -- Green
        amountValueText.rgba =
            0x55CC55FF

    elseif amount > 250 then

        -- Yellow
        amountValueText.rgba =
            0xFFD54FFF

    else

        -- Red
        amountValueText.rgba =
            0xDD5555FF

    end


    -- / 1000 is always green
    amountMaxText.rgba =
        0x55CC55FF
end


--------------------------------------------------
-- SHOW UNMAPPED TROUGH
--------------------------------------------------

function Window:ShowUnmapped(x, z)

    if popupDismissed then
        return
    end

    myGroupBox.hidden = false

    myText.hidden = false

    myText.content =
        "Unmapped POF Trough" ..
        "<br><br>" ..
        "Position: " ..
        tostring(x) ..
        ", " ..
        tostring(z)

    -- No amount data available
    amountLabel.hidden = true
    amountValueText.hidden = true
    amountMaxText.hidden = true
end


--------------------------------------------------
-- RESET DISMISSED STATE
--------------------------------------------------

function Window:ResetDismissed()

    popupDismissed = false
end


--------------------------------------------------
-- IS DISMISSED
--------------------------------------------------

function Window:IsDismissed()

    return popupDismissed
end


--------------------------------------------------
-- HIDE WINDOW
--------------------------------------------------

function Window:Hide()

    myGroupBox.hidden = true
end


--------------------------------------------------
-- RETURN MODULE
--------------------------------------------------

return Window