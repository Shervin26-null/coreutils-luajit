local VERSION = "luajit-coreutils expand 0.1"

local initial = false
local tabstops = {8}
local repeat_tab = nil
local relative = false
local files = {}

local function parse_tabs(s)
    tabstops = {}
    repeat_tab = nil
    relative = false

    local last = 0

    for part in s:gmatch("[^,]+") do
        if part:sub(1,1) == "/" then
            repeat_tab = tonumber(part:sub(2))
        elseif part:sub(1,1) == "+" then
            repeat_tab = tonumber(part:sub(2))
            relative = true
        else
            local n = tonumber(part)
            if n then
                tabstops[#tabstops+1] = n
                last = n
            end
        end
    end

    if #tabstops == 0 then
        tabstops = {8}
    end
end

local function next_tab(col)
    for _, n in ipairs(tabstops) do
        if n > col then
            return n
        end
    end

    if repeat_tab then
        if relative then
            return col + repeat_tab - (col % repeat_tab)
        else
            local n = tabstops[#tabstops]
            while n <= col do
                n = n + repeat_tab
            end
            return n
        end
    end

    local n = tabstops[#tabstops]
    while n <= col do
        n = n + (tabstops[2] and tabstops[2] - tabstops[1] or 8)
    end
    return n
end

local args = {...}
local i = 1

while i <= #args do
    local a = args[i]

    if a == "-i" or a == "--initial" then
        initial = true

    elseif a == "-t" or a == "--tabs" then
        i = i + 1
        parse_tabs(args[i])

    elseif a:sub(1,3) == "-t=" then
        parse_tabs(a:sub(4))

    elseif a:sub(1,2) == "-t" then
        parse_tabs(a:sub(3))

    elseif a:sub(1,7) == "--tabs=" then
        parse_tabs(a:sub(8))

    elseif a == "--version" then
        print(VERSION)
        os.exit()

    elseif a == "--help" then
        print([[
Usage: expand [OPTION]... [FILE]...

Convert tabs in each FILE to spaces.

  -i, --initial        do not convert tabs after non blanks
  -t, --tabs=N         have tabs N characters apart, not 8
  -t, --tabs=LIST      use comma separated list of tab positions
      --help           display this help and exit
      --version        output version information and exit
]])
        os.exit()

    else
        files[#files+1] = a
    end

    i = i + 1
end

local function process(f)
    for line in f:lines() do
        local col = 0
        local seen = false
        local out = {}

        for c in line:gmatch(".") do
            if c == "\t" and (not initial or not seen) then
                local stop = next_tab(col)
                local spaces = stop - col
                out[#out+1] = string.rep(" ", spaces)
                col = stop
            else
                out[#out+1] = c
                col = col + 1
                if c ~= " " then
                    seen = true
                end
            end
        end

        print(table.concat(out))
    end
end

if #files == 0 then
    process(io.stdin)
else
    for _, file in ipairs(files) do
        local f, err = io.open(file, "r")
        if not f then
            io.stderr:write("expand: ", file, ": ", err, "\n")
        else
            process(f)
            f:close()
        end
    end
end
