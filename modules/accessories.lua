---------------------------------------------------------------------------------
-- accessories.lua — Item definitions for the marketplace
-- Reconstructed from decompiled accessories.lu.lua
---------------------------------------------------------------------------------
local accessories = {}

-- Avatar list: { name, id, price, imageKey }
local avatarList = {
    { name = "Fox",            id = 100, price = 0,          image = "fox" },
    { name = "Bear",           id = 101, price = 100,        image = "bear" },
    { name = "Panda",          id = 106, price = 300,        image = "panda" },
    { name = "Turtle",         id = 102, price = 750,        image = "turtle" },
    { name = "Skunk",          id = 109, price = 1000,       image = "skunk" },
    { name = "Bunny",          id = 103, price = 2000,       image = "bunny" },
    { name = "Lion",           id = 105, price = 3000,       image = "lion" },
    { name = "Penguin",        id = 112, price = 3500,       image = "penguin" },
    { name = "Beaver",         id = 108, price = 4000,       image = "beaver" },
    { name = "Parrot",         id = 110, price = 4500,       image = "parrot" },
    { name = "Doe",            id = 104, price = 5000,       image = "doe" },
    { name = "Dog",            id = 115, price = 7500,       image = "dog" },
    { name = "Cat",            id = 124, price = 9000,       image = "cat" },
    { name = "Tiger",          id = 114, price = 10000,      image = "tiger" },
    { name = "Squirrel",       id = 117, price = 12000,      image = "squirrel" },
    { name = "Gecko",          id = 119, price = 15000,      image = "gecko" },
    { name = "Polar Bear",     id = 113, price = 18000,      image = "polarbear" },
    { name = "Wolf",           id = 111, price = 20000,      image = "wolf" },
    { name = "Cheetah",        id = 121, price = 25000,      image = "cheeta" },
    { name = "Mouse",          id = 116, price = 30000,      image = "mouse" },
    { name = "Bull",           id = 132, price = 32000,      image = "bull" },
    { name = "Hedgehog",       id = 136, price = 38000,      image = "hedgehog" },
    { name = "Bald Eagle",     id = 120, price = 40000,      image = "baldeagle" },
    { name = "Dragon",         id = 135, price = 42000,      image = "dragon" },
    { name = "Shark",          id = 122, price = 45000,      image = "shark" },
    { name = "Hippo",          id = 131, price = 48000,      image = "hippo" },
    { name = "Monkey",         id = 107, price = 50000,      image = "monkey" },
    { name = "Rhino",          id = 133, price = 52000,      image = "rhino" },
    { name = "Rooster",        id = 137, price = 55000,      image = "rooster" },
    { name = "Sheep",          id = 134, price = 58000,      image = "sheep" },
    { name = "Elephant",       id = 126, price = 60000,      image = "elephant" },
    { name = "Panther",        id = 128, price = 75000,      image = "panther" },
    { name = "White Tiger",    id = 129, price = 77000,      image = "whiteTiger" },
    { name = "Crocodile",      id = 123, price = 80000,      image = "crocodile" },
    { name = "Camel",          id = 125, price = 100000,     image = "camel" },
    { name = "Unicorn",        id = 127, price = 123456,     image = "unicorn" },
    { name = "Golden Monkey",  id = 118, price = 200000,     image = "goldmonkey" },
    { name = "Golden Dragon",  id = 130, price = 999999,     image = "goldenDragon" },
    { name = "Diamond Doe",    id = 198, price = 999999999,  image = "diamondDoe" },
    { name = "Golden Fox",     id = 199, price = 9999999999, image = "goldfox" },
}

-- Hat list: { name, id, price, spriteIndex }  (spriteIndex maps to hat{N}Sprite.png)
local hatList = {
    { name = "Nothing",        id = 200, price = 0,     sprite = 0 },
    { name = "Monocle",        id = 201, price = 20,    sprite = 1 },
    { name = "Pirate Patch",   id = 202, price = 80,    sprite = 2 },
    { name = "Bandana",        id = 222, price = 150,   sprite = 22 },
    { name = "Scumbag",        id = 203, price = 200,   sprite = 3 },
    { name = "Blonde Wig",     id = 218, price = 300,   sprite = 18 },
    { name = "Brown Wig",      id = 219, price = 400,   sprite = 19 },
    { name = "Shades",         id = 204, price = 500,   sprite = 4 },
    { name = "Santa Hat",      id = 212, price = 500,   sprite = 12 },
    { name = "Halo",           id = 207, price = 700,   sprite = 7 },
    { name = "Pumpkin",        id = 208, price = 1000,  sprite = 8 },
    { name = "Shutter",        id = 211, price = 1300,  sprite = 11 },
    { name = "Top Hat",        id = 216, price = 1500,  sprite = 16 },
    { name = "Bow",            id = 217, price = 1500,  sprite = 17 },
    { name = "Bow Hat",        id = 215, price = 1600,  sprite = 15 },
    { name = "Space Helmet",   id = 205, price = 2000,  sprite = 5 },
    { name = "Rastacap",       id = 230, price = 2500,  sprite = 30 },
    { name = "Wizard Hat",     id = 209, price = 3000,  sprite = 9 },
    { name = "Chef Hat",       id = 236, price = 3500,  sprite = 36 },
    { name = "Hipster",        id = 210, price = 4000,  sprite = 10 },
    { name = "Crown",          id = 206, price = 5000,  sprite = 6 },
    { name = "Beets by Schrute", id = 213, price = 5000, sprite = 13 },
    { name = "Biker Helmet",   id = 232, price = 5500,  sprite = 32 },
    { name = "Flower Hat",     id = 224, price = 6000,  sprite = 24 },
    { name = "Cowboy",         id = 223, price = 7500,  sprite = 23 },
    { name = "Keffiyeh",       id = 225, price = 8000,  sprite = 25 },
    { name = "Uncle Sam",      id = 226, price = 9000,  sprite = 26 },
    { name = "F-Baller",       id = 221, price = 10000, sprite = 21 },
    { name = "Flat Bill",      id = 237, price = 12000, sprite = 37 },
    { name = "Pot",            id = 234, price = 13000, sprite = 34 },
    { name = "Robber",         id = 228, price = 15000, sprite = 28 },
    { name = "Santa Beard",    id = 229, price = 18000, sprite = 29 },
    { name = "Clown",          id = 214, price = 20000, sprite = 14 },
    { name = "Dizzy Glasses",  id = 240, price = 21000, sprite = 40 },
    { name = "Flower Crown",   id = 233, price = 22000, sprite = 33 },
    { name = "Night Vision",   id = 241, price = 23000, sprite = 41 },
    { name = "Viking Helmet",  id = 231, price = 25000, sprite = 31 },
    { name = "Purple Shades",  id = 239, price = 28000, sprite = 39 },
    { name = "Squid",          id = 238, price = 30000, sprite = 38 },
    { name = "Pimp",           id = 227, price = 50000, sprite = 27 },
    { name = "Golden Helm",    id = 235, price = 100000, sprite = 35 },
}

-- Item/Effect list: { name, id, price, spriteIndex }
local itemList = {
    { name = "Nothing",          id = 300, price = 0,     sprite = 0 },
    { name = "Flowers",          id = 318, price = 20,    sprite = 18 },
    { name = "Matrix",           id = 301, price = 50,    sprite = 1 },
    { name = "Snowflakes",       id = 302, price = 100,   sprite = 2 },
    { name = "Beach Ball",       id = 320, price = 150,   sprite = 20 },
    { name = "Leaves",           id = 303, price = 200,   sprite = 3 },
    { name = "Bubbles",          id = 304, price = 300,   sprite = 4 },
    { name = "Parasol",          id = 322, price = 400,   sprite = 22 },
    { name = "Butterflies",      id = 305, price = 500,   sprite = 5 },
    { name = "Candy",            id = 310, price = 500,   sprite = 10 },
    { name = "Snowballs",        id = 324, price = 600,   sprite = 24 },
    { name = "Sea Stars",        id = 319, price = 700,   sprite = 19 },
    { name = "Candy Cane",       id = 315, price = 800,   sprite = 15 },
    { name = "Gingerbread",      id = 316, price = 900,   sprite = 16 },
    { name = "Stars",            id = 306, price = 1000,  sprite = 6 },
    { name = "Bats",             id = 309, price = 1000,  sprite = 9 },
    { name = "Spiders",          id = 313, price = 1000,  sprite = 13 },
    { name = "Skulls",           id = 311, price = 1250,  sprite = 11 },
    { name = "Music",            id = 307, price = 1500,  sprite = 7 },
    { name = "Hearts",           id = 308, price = 2000,  sprite = 8 },
    { name = "Clover",           id = 326, price = 2500,  sprite = 26 },
    { name = "Tracks",           id = 314, price = 3000,  sprite = 14 },
    { name = "Bones",            id = 330, price = 3333,  sprite = 30 },
    { name = "Basketballs",      id = 325, price = 4000,  sprite = 25 },
    { name = "Gifts",            id = 323, price = 5000,  sprite = 23 },
    { name = "#$*@!",            id = 334, price = 5500,  sprite = 34 },
    { name = "Shiny Balls",      id = 328, price = 6000,  sprite = 28 },
    { name = "Bakies",           id = 335, price = 6500,  sprite = 35 },
    { name = "X-mas Bells",      id = 327, price = 7000,  sprite = 27 },
    { name = "Popcorn",          id = 336, price = 7500,  sprite = 36 },
    { name = "Fire Balls",       id = 332, price = 8000,  sprite = 32 },
    { name = "Dollar Bills",     id = 312, price = 9999,  sprite = 12 },
    { name = "Lightning Clouds", id = 333, price = 12000, sprite = 33 },
    { name = "Amethyst",         id = 331, price = 15000, sprite = 31 },
    { name = "Rubies",           id = 329, price = 20000, sprite = 29 },
    { name = "Gold Coins",       id = 317, price = 30000, sprite = 17 },
    { name = "Diamonds",         id = 321, price = 45000, sprite = 21 },
}

-- Boots list: { name, id, price, spriteIndex }
local bootsList = {
    { name = "Nothing",              id = 400, price = 0,      sprite = 0 },
    { name = "Socks",                id = 412, price = 40,     sprite = 12 },
    { name = "Addy",                 id = 401, price = 80,     sprite = 1 },
    { name = "Naik",                 id = 402, price = 160,    sprite = 2 },
    { name = "Wellingtons",          id = 415, price = 200,    sprite = 15 },
    { name = "Curly Shoes",          id = 409, price = 300,    sprite = 9 },
    { name = "Santa Shoes",          id = 408, price = 400,    sprite = 8 },
    { name = "Konverte",             id = 403, price = 500,    sprite = 3 },
    { name = "Mordans",              id = 419, price = 600,    sprite = 19 },
    { name = "Green Shoes",          id = 420, price = 700,    sprite = 20 },
    { name = "Sanik",                id = 407, price = 850,    sprite = 7 },
    { name = "Skis",                 id = 417, price = 900,    sprite = 17 },
    { name = "Clops",                id = 413, price = 1000,   sprite = 13 },
    { name = "Vams",                 id = 423, price = 1100,   sprite = 23 },
    { name = "Pink Heels",           id = 421, price = 1200,   sprite = 21 },
    { name = "Slippers",             id = 422, price = 1400,   sprite = 22 },
    { name = "Skateboard",           id = 404, price = 1500,   sprite = 4 },
    { name = "MOGGS",                id = 427, price = 1800,   sprite = 27 },
    { name = "Clogs",                id = 436, price = 2000,   sprite = 36 },
    { name = "Hoverboard",           id = 405, price = 2200,   sprite = 5 },
    { name = "High Heels",           id = 411, price = 3000,   sprite = 11 },
    { name = "Skates",               id = 406, price = 4000,   sprite = 6 },
    { name = "Cowboy",               id = 414, price = 5000,   sprite = 14 },
    { name = "Santa Socks",          id = 426, price = 6000,   sprite = 26 },
    { name = "Black Shoes",          id = 425, price = 8000,   sprite = 25 },
    { name = "Mice",                 id = 424, price = 10000,  sprite = 24 },
    { name = "Purple Konverte",      id = 435, price = 11000,  sprite = 35 },
    { name = "Biker Shoes",          id = 433, price = 12000,  sprite = 33 },
    { name = "Surfboard",            id = 430, price = 15000,  sprite = 30 },
    { name = "Wave",                 id = 410, price = 20000,  sprite = 10 },
    { name = "Disco",                id = 416, price = 20000,  sprite = 16 },
    { name = "Clown Shoes",          id = 431, price = 30000,  sprite = 31 },
    { name = "Viking Shoes",         id = 432, price = 35000,  sprite = 32 },
    { name = "Snowboard",            id = 418, price = 40000,  sprite = 18 },
    { name = "Golden Sneakers",      id = 429, price = 50000,  sprite = 29 },
    { name = "Golden Medieval Shoes",id = 434, price = 100000, sprite = 34 },
    { name = "Golden Waveboard",     id = 428, price = 300000, sprite = 28 },
    { name = "Golden Hoverboard",    id = 437, price = 350000, sprite = 37 },
}

--------------------------------------------------------------------------------
-- Public API
--------------------------------------------------------------------------------

function accessories.getAvatarList()
    return avatarList
end

function accessories.getHatList()
    return hatList
end

function accessories.getItemList()
    return itemList
end

function accessories.getBootsList()
    return bootsList
end

-- Get a single item by ID (searches all categories)
function accessories.getItem(itemId)
    for _, item in ipairs(avatarList) do
        if item.id == itemId then return item end
    end
    for _, item in ipairs(hatList) do
        if item.id == itemId then return item end
    end
    for _, item in ipairs(itemList) do
        if item.id == itemId then return item end
    end
    for _, item in ipairs(bootsList) do
        if item.id == itemId then return item end
    end
    return nil
end

-- Get thumbnail image path for an item
function accessories.getThumbnail(category, item)
    if category == 1 then
        -- Avatar
        return "images/gui/market/accessories/" .. item.image .. ".png"
    elseif category == 2 then
        -- Hat
        if item.sprite == 0 then
            return "images/gui/market/accessories/transparent.png"
        end
        return "images/gui/market/accessories/hat" .. item.sprite .. "Sprite.png"
    elseif category == 3 then
        -- Item/Effect
        if item.sprite == 0 then
            return "images/gui/market/accessories/transparent.png"
        end
        return "images/gui/market/accessories/item" .. item.sprite .. "Sprite.png"
    elseif category == 4 then
        -- Boots
        if item.sprite == 0 then
            return "images/gui/market/accessories/transparent.png"
        end
        return "images/gui/market/accessories/boots" .. item.sprite .. "Sprite.png"
    end
    return "images/transparent.png"
end

return accessories
