local VERSION = "luajit-coreutils paste 0.1"

local delim = "\t"
local delim_index = 1
local serial = false
local zero = false
local files = {}

local function parse_delim(s)
    return s:gsub("\\t", "\t")
            :gsub("\\n", "\n")
            :gsub("\\0", "\0")
            :gsub("\\\\", "\\")
end

local args = {...}
local i = 1

while i <= #args do
    local a = args[i]

    if a == "-d" or a == "--delimiters" then
        i = i + 1
        delim = parse_delim(args[i])

    elseif a:sub(1,2) == "-d" then
        delim = parse_delim(a:sub(3))

    elseif a:sub(1,14) == "--delimiters=" then
        delim = parse_delim(a:sub(15))

    elseif a == "-s" or a == "--serial" then
        serial = true

    elseif a == "-z" or a == "--zero-terminated" then
        zero = true

    elseif a == "--version" then
        print(VERSION)
        os.exit()

    elseif a == "--help" then
        print([[
Usage: paste [OPTION]... [FILE]...

Write lines from files separated by TAB.

  -d, --delimiters=LIST   use characters from LIST instead of TAB
  -s, --serial            paste one file at a time
  -z, --zero-terminated   line delimiter is NUL
      --help              display this help and exit
      --version           output version information and exit
]])
        os.exit()

    else
        files[#files+1] = a
    end

    i = i + 1
end

local newline = zero and "\0" or "\n"

local function read_file(name)
    local f

    if name == "-" then
        f = io.stdin
    else
        f = assert(io.open(name, "r"))
    end

    local lines = {}

    for line in f:lines() do
        lines[#lines+1] = line
    end

    if f ~= io.stdin then
        f:close()
    end

    return lines
end

if #files == 0 then
    files[1] = "-"
end

if serial then
    for _, file in ipairs(files) do
        delim_index = 1
        local lines = read_file(file)

        for i, line in ipairs(lines) do
            if i > 1 then
                local d = delim:sub(delim_index, delim_index)

                if d == "" then
                    delim_index = 1
                    d = delim:sub(1,1)
                end

                io.write(d)

                delim_index = delim_index + 1
                if delim_index > #delim then
                    delim_index = 1
                end
            end
            io.write(line)
        end

        io.write(newline)
    end
else
    local all = {}

    for _, file in ipairs(files) do
        all[#all+1] = read_file(file)
    end

    local max = 0
    for _, t in ipairs(all) do
        if #t > max then
            max = #t
        end
    end

    for row = 1, max do
        for col = 1, #all do
            if col > 1 then
                local d = delim:sub(delim_index, delim_index)

                if d == "" then
                    delim_index = 1
                    d = delim:sub(1,1)
                end

                io.write(d)

                delim_index = delim_index + 1
                if delim_index > #delim then
                    delim_index = 1
                end
            end

            if all[col][row] then
                io.write(all[col][row])
            end
        end

        io.write(newline)
    end
end
