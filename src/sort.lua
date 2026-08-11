local VERSION = "luajit-coreutils sort 0.1"

local opts = {
    reverse = false,
    ignore_case = false,
    numeric = false,
    general_numeric = false,
    human_numeric = false,
    month = false,
    dictionary = false,
    ignore_blank = false,
    ignore_nonprinting = false,
    random = false,
    version = false,
    unique = false,
    stable = false,
    zero = false,
    check = false,
    quiet_check = false,
    merge = false,
    output = nil,
    separator = nil,
    key = nil,
}

local files = {}

local function help()
print([[
Usage: sort [OPTION]... [FILE]...

Write sorted concatenation of all FILE(s) to standard output.

With no FILE, or when FILE is -, read standard input.

  -b, --ignore-leading-blanks
  -d, --dictionary-order
  -f, --ignore-case
  -g, --general-numeric-sort
  -h, --human-numeric-sort
  -i, --ignore-nonprinting
  -M, --month-sort
  -n, --numeric-sort
  -R, --random-sort
  -r, --reverse
  -V, --version-sort

  -c, --check
  -k, --key=KEYDEF
  -m, --merge
  -o, --output=FILE
  -s, --stable
  -t, --field-separator=SEP
  -u, --unique
  -z, --zero-terminated

      --help
      --version
]])
end


local i = 1

while i <= #arg do
    local a = arg[i]

    if a == "--help" then
        help()
        os.exit(0)

    elseif a == "--version" then
        print(VERSION)
        os.exit(0)

    elseif a == "-r" or a == "--reverse" then
        opts.reverse = true

    elseif a == "-f" or a == "--ignore-case" then
        opts.ignore_case = true

    elseif a == "-n" or a == "--numeric-sort" then
        opts.numeric = true

    elseif a == "-g" or a == "--general-numeric-sort" then
        opts.general_numeric = true

    elseif a == "-h" or a == "--human-numeric-sort" then
        opts.human_numeric = true

    elseif a == "-V" or a == "--version-sort" then
        opts.version = true

    elseif a == "-M" or a == "--month-sort" then
        opts.month = true

    elseif a == "-b" or a == "--ignore-leading-blanks" then
        opts.ignore_blank = true

    elseif a == "-d" or a == "--dictionary-order" then
        opts.dictionary = true

    elseif a == "-i" or a == "--ignore-nonprinting" then
        opts.ignore_nonprinting = true

    elseif a == "-R" or a == "--random-sort" then
        opts.random = true

    elseif a == "-u" or a == "--unique" then
        opts.unique = true

    elseif a == "-s" or a == "--stable" then
        opts.stable = true

    elseif a == "-z" or a == "--zero-terminated" then
        opts.zero = true

    elseif a == "-c" or a == "--check" then
        opts.check = true

    elseif a == "-C" then
        opts.quiet_check = true

    elseif a == "-k" or a == "--key" then
        i = i + 1
        opts.key = arg[i]

    elseif a:match("^%-k") then
        opts.key = a:sub(3)

    elseif a == "-t" or a == "--field-separator" then
        i = i + 1
        opts.separator = arg[i]

    elseif a == "-o" or a == "--output" then
        i = i + 1
        opts.output = arg[i]

    elseif a == "-m" or a == "--merge" then
        opts.merge = true

    else
        files[#files + 1] = a
    end

    i = i + 1
end


if #files == 0 then
    files[1] = "-"
end

local function read_file(name)
    local lines = {}

    if name == "-" then
        for line in io.lines() do
            lines[#lines + 1] = line
        end
        return lines
    end

    local f = io.open(name, "rb")

    if not f then
        io.stderr:write("sort: cannot read '", name, "'\n")
        return nil
    end

    for line in f:lines() do
        lines[#lines + 1] = line
    end

    f:close()

    return lines
end


local function normalize(s)

    if opts.ignore_blank then
        s = s:gsub("^%s+", "")
    end

    if opts.ignore_case then
        s = s:upper()
    end

    if opts.dictionary then
        s = s:gsub("[^%w%s]", "")
    end

    if opts.ignore_nonprinting then
        s = s:gsub("[%z\1-\31\127]", "")
    end

    return s
end


local months = {
    JAN=1,FEB=2,MAR=3,APR=4,MAY=5,JUN=6,
    JUL=7,AUG=8,SEP=9,OCT=10,NOV=11,DEC=12
}


local function get_key(line)

    if not opts.key then
        return line
    end

    local field = tonumber(opts.key:match("^(%d+)"))

    if not field then
        return line
    end

    local sep = opts.separator

    local parts = {}

    if sep then
        for part in line:gmatch("[^"..sep.."]+") do
            parts[#parts+1] = part
        end
    else
        for part in line:gmatch("%S+") do
            parts[#parts+1] = part
        end
    end

    return parts[field] or ""
end


local function human_number(s)

    local n, u = s:match("^([%d%.]+)(%a*)")

    if not n then
        return 0
    end

    n = tonumber(n)

    local m = {
        K=1024,
        M=1024^2,
        G=1024^3,
        T=1024^4
    }

    return n * (m[u] or 1)
end


local function version_key(s)
    local out = {}

    for part in s:gmatch("%d+") do
        out[#out+1] = string.format("%010d", tonumber(part))
    end

    return table.concat(out) .. s
end


local function compare(a,b)

    local ka = get_key(a)
    local kb = get_key(b)

    local va
    local vb


    if opts.numeric or opts.general_numeric then

        va = tonumber(ka) or 0
        vb = tonumber(kb) or 0

    elseif opts.human_numeric then

        va = human_number(ka)
        vb = human_number(kb)

    elseif opts.month then

        va = months[ka:upper()] or 0
        vb = months[kb:upper()] or 0

    elseif opts.version then

        va = version_key(ka)
        vb = version_key(kb)

    else

        va = normalize(ka)
        vb = normalize(kb)

    end


    if va == vb and not opts.stable then
        va = a
        vb = b
    end


    local result = va < vb


    if va == vb then
        return false
    end

    if opts.reverse then
        return va > vb
    end

    return va < vb
end


local lines = {}

for _, file in ipairs(files) do

    local data = read_file(file)

    if data then
        for _, line in ipairs(data) do
            lines[#lines+1] = line
        end
    end

end


if opts.check then

    for i = 2, #lines do

        if compare(lines[i], lines[i-1]) then

            if not opts.quiet_check then
                io.stderr:write(
                    "sort: disorder: ",
                    lines[i],
                    "\n"
                )
            end

            os.exit(1)
        end

    end

    os.exit(0)
end


table.sort(lines, compare)


if opts.unique then

    local out = {}
    local last

    for _, line in ipairs(lines) do

        if line ~= last then
            out[#out+1] = line
            last = line
        end

    end

    lines = out
end


local sep = "\n"

if opts.zero then
    sep = "\0"
end


local result = table.concat(lines, sep) .. sep


if opts.output then

    local f = io.open(opts.output,"wb")

    if not f then
        io.stderr:write("sort: cannot write file\n")
        os.exit(1)
    end

    f:write(result)
    f:close()

else

    io.write(result)

end
