local VERSION = "luajit-coreutils unexpand 0.1"

local all = false
local first_only = false
local tabsize = 8
local files = {}

local args = {...}
local i = 1

while i <= #args do
    local a = args[i]

    if a == "-a" or a == "--all" then
        all = true

    elseif a == "--first-only" then
        first_only = true
        all = false

    elseif a == "-t" or a == "--tabs" then
        i = i + 1
        tabsize = tonumber(args[i]) or 8
        all = true

    elseif a:sub(1,2) == "-t" then
        tabsize = tonumber(a:sub(3)) or 8
        all = true

    elseif a:sub(1,7) == "--tabs=" then
        tabsize = tonumber(a:sub(8)) or 8
        all = true

    elseif a == "--version" then
        print(VERSION)
        os.exit()

    elseif a == "--help" then
        print([[
Usage: unexpand [OPTION]... [FILE]...

Convert blanks to tabs.

  -a, --all             convert all blanks
      --first-only      convert only leading blanks
  -t, --tabs=N          have tabs N characters apart
      --help            display this help and exit
      --version         output version information and exit
]])
        os.exit()

    else
        files[#files+1] = a
    end

    i = i + 1
end


local function process(f)
    for line in f:lines() do
        local out = {}
        local col = 0
        local leading = true
        local spaces = 0

        local function flush()
            while spaces > 0 do
                local next_tab = tabsize - (col % tabsize)

                if spaces >= next_tab then
                    out[#out+1] = "\t"
                    spaces = spaces - next_tab
                    col = col + next_tab
                else
                    out[#out+1] = string.rep(" ", spaces)
                    col = col + spaces
                    spaces = 0
                end
            end
        end

        for c in line:gmatch(".") do
            if c == " " and (all or leading) then
                spaces = spaces + 1
            else
                flush()
                out[#out+1] = c
                col = col + 1

                if c ~= " " then
                    leading = false
                end
            end
        end

        flush()
        print(table.concat(out))
    end
end

if #files == 0 then
    process(io.stdin)
else
    for _, file in ipairs(files) do
        local f, err = io.open(file, "r")

        if not f then
            io.stderr:write("unexpand: ", file, ": ", err, "\n")
        else
            process(f)
            f:close()
        end
    end
end
