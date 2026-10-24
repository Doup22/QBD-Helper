print("POF Helper loaded!")


--------------------------------------------------
-- MODULES
--------------------------------------------------

local Window = require("window")
local TroughData = require("trough_data")


--------------------------------------------------
-- GET FOOD NAME
--------------------------------------------------

local function getFoodName(amount, category)

    if amount == 0 then
        return "Empty"
    end

    return
        TroughData.foodCategories[category]
        or
        "Unknown (" ..
        tostring(category) ..
        ")"
end


--------------------------------------------------
-- MINIMENU HOVER
--------------------------------------------------

local function miniMenuReady(miniMenuReadyEvent)

    local entries =
        miniMenuReadyEvent.miniMenu.entries

    local hoveringTrough = false


    for _, entry in pairs(entries) do

        if entry.locData ~= nil then

            local subject =
                tostring(entry.subjectText)


            --------------------------------------------------
            -- CHECK FOR TROUGH
            --------------------------------------------------

            if string.find(
                string.lower(subject),
                "trough",
                1,
                true
            ) then

                hoveringTrough = true

                local loc =
                    entry.locData


                --------------------------------------------------
                -- BUILD LOCATION KEY
                --------------------------------------------------

                local locationKey =
                    tostring(loc.coordGridX) ..
                    "," ..
                    tostring(loc.coordGridZ)


                --------------------------------------------------
                -- FIND TROUGH
                --------------------------------------------------

                local trough =
                    TroughData.locations[locationKey]


                --------------------------------------------------
                -- KNOWN TROUGH
                --------------------------------------------------

                if trough ~= nil then

                    local amount =
                        var.VarPlayer.FromID(
                            trough.amountVar
                        ).value

                    local category =
                        var.VarPlayer.FromID(
                            trough.categoryVar
                        ).value


                    --------------------------------------------------
                    -- FOOD TYPE
                    --------------------------------------------------

                    local foodName =
                        getFoodName(
                            amount,
                            category
                        )


                    --------------------------------------------------
                    -- SEND DATA TO WINDOW
                    --------------------------------------------------

                    Window:ShowTrough(
                        trough.number,
                        foodName,
                        amount
                    )

                    break
                end


                --------------------------------------------------
                -- UNMAPPED TROUGH
                --------------------------------------------------

                Window:ShowUnmapped(
                    loc.coordGridX,
                    loc.coordGridZ
                )

                break
            end
        end
    end


    --------------------------------------------------
    -- ALLOW CLOSED WINDOW TO REOPEN
    --------------------------------------------------

    if not hoveringTrough then
        Window:ResetDismissed()
    end
end


--------------------------------------------------
-- MINIMENU EVENT
--------------------------------------------------

Event.MiniMenuReady.Subscribe(
    "POF_TroughHover",
    miniMenuReady
)