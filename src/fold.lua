local VERSION = "luajit-coreutils fold 0.1"

local width = 80
local bytes = false
local characters = false
local spaces = false
local files = {}
local chars = true

local args = {...}
local i = 1

while i <= #args do
    local a = args[i]

    if a == "-w" or a == "--width" then
        i = i + 1
        width = tonumber(args[i])

    elseif a:sub(1,3) == "-w=" then
        width = tonumber(a:sub(4))

    elseif a:sub(1,2) == "-w" then
        width = tonumber(a:sub(3))

    elseif a == "-b" or a == "--bytes" then
        bytes = true
        characters = false

    elseif a == "-c" or a == "--characters" then
        characters = true
        bytes = false

    elseif a == "-s" or a == "--spaces" then
        spaces = true

    elseif a == "--version" then
        print(VERSION)
        os.exit()

    elseif a == "--help" then
        print([[
Usage: fold [OPTION]... [FILE]...

Wrap input lines in each FILE.

  -b, --bytes          count bytes rather than columns
  -c, --characters     count characters rather than columns
  -s, --spaces         break after blanks, or in words greater than WIDTH
  -w, --width=WIDTH    use WIDTH columns instead of 80
      --help           display this help and exit
      --version        output version information and exit
]])
        os.exit()

    else
        files[#files+1] = a
    end

    i = i + 1
end

local function fold_line(line)
    while #line > width do
        local cut = width

        if spaces then
            local pos = line:sub(1, width):match("^.*()%s")
            if pos then
                cut = pos
            end
        end

        print(line:sub(1, cut))
        line = line:sub(cut + 1)
    end

    print(line)
end


local function process(f)
    for line in f:lines() do
        fold_line(line)
    end
end


if #files == 0 then
    process(io.stdin)
else
    for _, file in ipairs(files) do
        local f, err = io.open(file, "r")

        if not f then
            io.stderr:write("fold: ", file, ": ", err, "\n")
        else
            process(f)
            f:close()
        end
    end
end
