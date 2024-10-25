-- cs2d demo recording and replay script
-- visit my github repository: github.com/carnivohra/demoplayer

-- initialize vars
demoplayer = {
    memory = {},
    constants = {
        demos_path = "demos"
        demo_format = ".dem2d"
    }
}

-- for recording
function demoplayer:record(name)
    -- filter for a playing demoplayer
    if self.state == "playing" then
        -- stop execution
        return print("Can't record during demo playback.") -- print error in console
    elseif self.state == "recording" then self:stop() end -- stop recording previous demo

    -- name schould be the current date and time in a format like "year-month-day_hour-minute-second"
    -- for an example:"2012-11-28_18-56-29"
    if name == nil then name = os.date("%Y-%m-%d_%H-%M-%S") end 

    -- create demos folder
    os.execute("mkdir" .. self.constants.demos_path) -- i need a better solution for this ... 
    -- file_name should be like "demos/mydemo.dem2d"
    local file_name = self.constants.demos_path .. "/" .. name .. self.constants.demo_format
    -- index for file_name expandation in case there is already a demo named the same
    local i = 0

    -- while file with file_name exists
    while self:file_exists(file_name) do
        i = i + 1 -- first index is "1"
        -- if "demos/mydemo.dem2d" already exists then file_name should be like "demos/mydemo-1.dem2d"
        -- even if this file already exists then file_name should be like "demos/mydemo-2.dem2d" and so on ...
        file_name = self.constants.demos_path .. "/" .. name .. "-" .. i .. self.constants.demo_format
    end

    -- open stream to file 
    local stream = io.open(file_name, "wb")
    -- put the file into the memory to get access from outside
    self.memory.file = { name = file_name, stream = stream }
    self.state = "recording" -- set state to recording
    print("Recording to " .. file_name .. ".")
    
    -- current game data
    local data = self:current_data()
    -- write game data to demo file
    self:write(data)
end

function demoplayer:stop()
    if self.state == nil then
         -- stop execution
        return print("No recording or demo playback is currently running.")
    end

    -- cache noch leeren lassen vorm stream close
    local stream = self.memory.file.stream
    
    if stream ~= nil then stream:close() end

    self.memory = {}
    self.state = nil
    print("Completed demo.")
end

demoplayer.version = "0.1"

function demoplayer:current_data()
    return { 
        demoplayer_version = self.version,
        cs2d_version = game("version"), 
        environment = self:current_environment() 
    }
end

function demoplayer:current_environment()
    return { 
        map = self:current_map(),
        game = self:current_game()
    }
end

demoplayer.constants.maps_path = "maps"
demoplayer.constants.tile_set_path = "gfx/tiles"

function demoplayer:current_map()
    local name = map("name")
    local map = {
        name = name,
        files = {
            info = { name = self.constants.maps_path .. "/" .. name .. ".txt", raw },
            map = { name = self.constants.maps_path .. "/" .. name .. ".map", raw },
            tile_set = { name = self.constants.tile_set_path .. "/" .. map("tileset"), raw },
            tile_set_ini = { name = (self.constants.tile_set_path .. "/" .. map("tileset")):sub(0, -5) .. ".inf", raw }
        }
    }   

    for i, file in pairs(map.files) do
        if self:file_exists(file.name) then
            file.raw = self:read_file(file.name)
        else map.files[i] = nil end
    end

    return map
end

function demoplayer:read_file(file_name)
    if not self:file_exists(file_name) then return nil end
    
    local stream = io.open(file_name, "rb")
    local content = stream:read("*all")
    stream:close()
    return content
end

function demoplayer:current_game()
    return { 
        settings = self:current_game_settings(), 
        entities = self:current_game_entities()
    }
end

demoplayer.constants.game = { 
    settings = {
        "sv_name", "sv_hostport", "sv_password", "sv_rcon", "sv_maxplayers", "sv_fow", "sv_friendlyfire", 
        "sv_lan", "sv_usgnonly", "sv_maptransfer", "sv_offscreendamage", "sv_forcelight", "sv_voicechat", 
        "mp_recoil", "sv_gamemode", "sv_specmode", "sv_map", "mp_timelimit", "mp_winlimit", "mp_roundlimit", 
        "sv_freezetime", "mp_buytime", "mp_startmoney", "mp_teamkillpenalty", "mp_teamkillpenalty",
        "mp_hostagepenalty", "mp_tkpunish", "mp_idlekick", "mp_vulnerablehostages", "mp_autoteambalance",
        "mp_spectatemouse", "bot_prefix", "bot_count", "bot_autofill", "bot_keepfreeslots", "bot_jointeam",
        "bot_skill", "bot_weapons", "mp_anticlock", "mp_supply_items"
    }
}

function demoplayer:current_game_settings()
    local settings = {}

    for i = 1, #self.constants.game.settings do
        local key = self.constants.game.settings[i]
        settings[i] = game(key)
    end

    return settings
end

function demoplayer:current_game_entities()
    return { players = self:current_game_entities_players() }
end

function demoplayer:current_game_entities_players()
    local players = {}
    local online_ids = player(0, "table")

    for i = 1, #online_ids do
        local id = online_ids[i]
        players[#players + 1] = self:current_player(id)
    end

    return players
end

function demoplayer:current_player(id)
    return {
        id = id,
        name = player(id, "name"),
        bot = player(id, "bot"),
        ip = player(id, "ip"),
        port = player(id, "port"),
        ping = player(id, "ping"),
        language = player(id, "language"),
        rcon = player(id, "rcon"),
        usgn = {
            id = player(id, "usgn"),
            name = player(id, "usgnname")
        },
        steam = {
            id = player(id, "steamid"),
            name = player(id, "steamname")
        },
        settings = {
            spray = {
                file = player(id, "sprayname"),
                color = player(id, "color")
            },
            screen = {
                width = player(id, "screenw"),
                height = player(id, "screenh"),
                wide = player(id, "widescreen"),
                windowed = player(id, "windowed"),
            },
            mic_support = player(id, "micsupport")
        },
        team = {
            id = player(id, "team"),
            unit = player(id, "look")
        },
        health = {
            current = player(id, "haelth"),
            max = player(id, "maxhealth")
        },
        armor = player(id, "armor"),
        position = {
            x = player(id, "x"),
            y = player(id, "y")
        },
        rotation = player(id, "rotation"),
        mouse = {
            x = player(id, "mousemapx"),
            y = player(id, "mousemapy")
        },
        money = player(id, "money"),
        score = {
            total = player(id, "score"),
            deaths = player(id, "deaths"),
            team_kills = player(id, "teamkills"),
            hostage_kills = player(id, "hostagekills"),
            team_building_kills = player(id, "teambuildingkills"),
            mvps = player(id, "mvp"),
            assists = player(id, "assists")
        },
        idle = player(id, "idle"),
        speedmod = player(id, "speedmod"),
        spectating = player(id, "spectating"),
        ai_flash = player(id, "ai_flash")
    }
end

function demoplayer:write(data)
    local encoded = self:encode(data)
    self.memory.file.stream:write(encoded)
end

demoplayer.constants.encoder = {
    types = { "nil", "boolean", "number", "string", "function", "userdata", "thread", "table" }
}

function demoplayer:encode(field) 
    local field_type = type(field)
    local type_index

    for i = 1, #self.constants.encoder.types do
        local _type = self.constants.encoder.types[i]

        if _type == field_type then type_index = i end
    end

    local encoded = tostring(type_index)
    
    if type(field) == "boolean" then 
        encoded = encoded .. ( field and "1" or "0" )

    elseif type(field) == "number" or type(field) == "string" then 
        local field_length = #tostring(field)
        local field_length_length = #tostring(field_length)
        encoded = encoded .. field_length_length .. field_length .. field

    elseif type(field) == "table" then
        local field_length = #field
        local field_length_length = #tostring(field_length)
        encoded = encoded .. field_length_length .. field_length

        for i, field_field in pairs(field) do
            encoded = encoded .. self:encode(field_field)
        end
    end

    return encoded
end

function demoplayer:load(file_name)
    if not self:file_exists(file_name) then
        return print("Could not open file " .. file_name .. ".")
    end

    if self.state ~= nil then self:stop() end
    
    local data = self:read_file(file_name)

    -- decode data
end

function demoplayer:decode(data)
    if data == nil then return nil end
    if data == "" then return nil end

    local type_index_string, data = self:cut_out(data, 1)
    local type_index = tonumber(type_index_string)

    if type_index == nil then 
        return print("Failed to decode data.")
    end

    local _type = self.constants.encoder.types[type_index]

    if _type == "nil" then return nil end

    if #data == 0 then 
        return print("Failed to decode data.")
    end

    if _type == "boolean" then
        local value_string, data = self:cut_out(data, 1)
        if value_string == "0" then return false end
        if value_string == "1" then return true end 
    
    elseif _type == "number" then
        local length_length_string, data = self:cut_out(data, 1)
        local length_string, data = self:cut_out(data, tonumber(length_length))
        local value_string = self:cut_out(data, tonumber(length))
        local value = tonumber(value_string)

        if value == nil then return print("Failed to decode data.") end
        return value

    elseif _type == "table" then
        local field_length_length, data = self:cut_out(data, 1)
        local field_length, data = self:cut_out(data, field_length_length)

        for i, field_length do
            value_string, data = self:cut_out(data, )
        end
    end


end

function demoplayer:cut_out(data, length)
    if length > #data then return print("Failed to cut out data.") end

    local cutted = ""

    for i = 1, length do
        cutted = cutted .. data[i]
    end

    return cutted, data:gsub(length)
end

function demoplayer:file_exists(file_name)
    local sum = checksumfile(file_name)

    if sum == nil then return nil end
    if sum == "" then return false end
    return true
end