---@class LoveExt.SerializeTable
local serde = {}

local parent_path = (...):match("(.-)[^%.]+$")

local load_env = {}

--- Returns a "Lua" portable version of the string (by quoting it)
local function exportstring(s)
    return string.format("%q", s)
end

local function loadchunk(chunk)
    local ftables = chunk
    if ftables == nil then return nil, "table load chunk is nil" end
    local success, tables = pcall(ftables)
    if not success then return nil, tables end
    for idx = 1, #tables do
        local tolinki = {}
        for i, v in pairs(tables[idx]) do
            if type(v) == "table" then
                tables[idx][i] = tables[v[1]]
            end
            if type(i) == "table" and tables[i[1]] then
                table.insert(tolinki, { i, tables[i[1]] })
            end
        end
        -- link indices
        for _, v in ipairs(tolinki) do
            tables[idx][v[2]], tables[idx][v[1]] = tables[idx][v[1]], nil
        end
    end
    return tables[1]
end

local nop = function(...)
end

---Creates a stringbuffer object that behaves like a file.
---@return table
local function stringwriter()
    return {
        data = {},
        write = function(self, ...)
            local arg = { ... }
            local i = #self.data
            for _, s in ipairs(arg) do
                i = i + 1
                self.data[i] = tostring(s)
            end
        end,
        close = function(self)
            self.write = nop
            self.close = nop
            self.output = table.concat(self.data)
        end,
    }
end

---Writes a serialized table to a file-like object.
---Does not serialize any functions, userdata, or any keys in the `_volatile` table of `tbl`.
---@param tbl table
---@param file any Any object with a write function in the form `function write(self, string)`
---@return nil, string? errmsg
function serde.write(tbl, file)
    local charS, charE = "   ", "\n"
    --local file, err = io.open(filename, "wb")
    if file == nil or file.write == nil then return nil, "file is not writable" end
    local ignore = tbl._volatile or {}     -- set of keys marked to not be saved
    -- initiate variables for save procedure
    local tables, lookup = { tbl }, { [tbl] = 1 }
    file:write("return {" .. charE)

    for idx, t in ipairs(tables) do
        file:write("--[" .. idx .. "]" .. charE)
        file:write("{" .. charE)
        local thandled = {}

        for i, v in ipairs(t) do
            if not ignore[i] then
                thandled[i] = true
                local stype = type(v)
                -- only handle value
                if stype == "table" then
                    if not lookup[v] then
                        table.insert(tables, v)
                        lookup[v] = #tables
                    end
                    file:write(charS .. "{" .. lookup[v] .. "}," .. charE)
                elseif stype == "string" then
                    file:write(charS .. exportstring(v) .. "," .. charE)
                elseif stype == "number" then
                    file:write(charS .. tostring(v) .. "," .. charE)
                end
            end
        end

        for i, v in pairs(t) do
            -- escape handled values
            if (not ignore[i] and not thandled[i]) then
                local str = ""
                local stype = type(i)
                -- handle index
                if stype == "table" then
                    if not lookup[i] then
                        table.insert(tables, i)
                        lookup[i] = #tables
                    end
                    str = charS .. "[{" .. lookup[i] .. "}]="
                elseif stype == "string" then
                    str = charS .. "[" .. exportstring(i) .. "]="
                elseif stype == "number" or stype == "boolean" then
                    str = charS .. "[" .. tostring(i) .. "]="
                end

                if str ~= "" then
                    stype = type(v)
                    -- handle value
                    if stype == "table" then
                        if not lookup[v] then
                            table.insert(tables, v)
                            lookup[v] = #tables
                        end
                        file:write(str .. "{" .. lookup[v] .. "}," .. charE)
                    elseif stype == "string" then
                        file:write(str .. exportstring(v) .. "," .. charE)
                    elseif stype == "number" or stype == "boolean" then
                        file:write(str .. tostring(v) .. "," .. charE)
                    end
                end
            end
        end
        file:write("}," .. charE)
    end
    file:write("}")
end

---Serializes a table to a file.
---Does not serialize any functions, userdata, or any keys in the `_volatile` table of `t`.
---
---The file is actually lua source code that, when run, produces the table.
---For security reasons, the code is run without any access to external code,
---which is why serialization of custom types is not possible.
---@param t table
---@param filename string
---@return boolean success, string? errmsg
function serde.savefile(t, filename)
    local file, err = io.open(filename, "wb")
    if file == nil then return false, err end
    serde.write(t, file)
    file:close()
    return true
end

---Serializes a table to a string.
---Does not serialize any functions, userdata, or any keys in the `_volatile` table of `t`.
---
---The string is actually lua source code that, when run, produces the table.
---For security reasons, the code is run without any access to external code,
---which is why serialization of custom types is not possible.
---@param t table
---@return string
function serde.savestring(t)
    local writer = stringwriter()
    serde.write(t, writer)
    writer:close()
    return writer.output
end

---Deserializes a table from a file. The file is lua source code.
---For security reasons, the file is run without access to any external code.
---
---Also, for security reasons, this file must not be lua bytecode.
---See: https://saelo.github.io/posts/pwning-lua-through-load.html
---@param filename string
---@return table?, string? errmsg
function serde.loadfile(filename)
    local chunk, err = loadfile(filename, "t", load_env)
    if chunk == nil then return nil, err end
    return loadchunk(chunk)
end

---Deserializes a table from a string of lua source code.
---For security reasons, the string is run without access to any external code.
---@param str string
---@return table?, string? errmsg
function serde.loadstring(str)
    if str == nil then return end
    local chunk, err = loadstring(str, "table_load")
    if chunk == nil then return nil, err end
    chunk = setfenv(chunk, load_env)
    return loadchunk(chunk)
end

return serde