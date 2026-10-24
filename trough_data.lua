local TroughData = {}


--------------------------------------------------
-- PHYSICAL TROUGH LOCATIONS
--------------------------------------------------

TroughData.locations = {

    ["2651,3338"] = {
        number = 1,
        amountVar = -41789,
        categoryVar = -41788
    },

    ["2642,3341"] = {
        number = 2,
        amountVar = -41791,
        categoryVar = -41790
    },

    ["2671,3357"] = {
        number = 3,
        amountVar = -41793,
        categoryVar = -41792
    },

    ["2655,3370"] = {
        number = 4,
        amountVar = -41795,
        categoryVar = -41794
    },

    ["2631,3370"] = {
        number = 5,
        amountVar = -41797,
        categoryVar = -41796
    },

    ["2660,3343"] = {
        number = 6,
        amountVar = -41799,
        categoryVar = -41798
    },

    ["2673,3372"] = {
        number = "Breeding",
        amountVar = -41801,
        categoryVar = -41800
    }
}


--------------------------------------------------
-- FOOD / MUSH CATEGORIES
--------------------------------------------------

TroughData.foodCategories = {
    [4] = "Mushy mush",
    [5] = "Fishy mush",
    [7] = "Variety mush",
    [8] = "Seedy mush"
}


return TroughData