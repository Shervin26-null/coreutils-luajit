local VERSION = "luajit-coreutils uniq 0.1"

local opts = {
    count = false,
    repeated = false,
    all_repeated = false,
    unique = false,
    ignore_case = false,
    zero = false,
    skip_fields = 0,
    skip_chars = 0,
    check_chars = nil,
}

local files = {}

local function help()
    print("Usage: uniq [OPTION]... [INPUT [OUTPUT]]")
    print("")
    print("  -c, --count")
    print("         prefix lines by the number of occurrences")
    print("  -d, --repeated")
    print("         only print duplicate lines")
    print("  -D")
    print("         print all duplicate lines")
    print("  -f, --skip-fields=N")
    print("         skip first N fields")
    print("  -i, --ignore-case")
    print("         ignore case")
    print("  -s, --skip-chars=N")
    print("         skip first N characters")
    print("  -u, --unique")
    print("         only print unique lines")
    print("  -w, --check-chars=N")
    print("         compare only N characters")
    print("  -z, --zero-terminated")
    print("         line delimiter is NUL")
    print("      --help")
    print("         display this help")
    print("      --version")
    print("         output version information")
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

    elseif a == "-c" or a == "--count" then
        opts.count = true

    elseif a == "-d" or a == "--repeated" then
        opts.repeated = true

    elseif a == "-D" or a == "--all-repeated" then
        opts.all_repeated = true

    elseif a == "-u" or a == "--unique" then
        opts.unique = true

    elseif a == "-i" or a == "--ignore-case" then
        opts.ignore_case = true

    elseif a == "-z" or a == "--zero-terminated" then
        opts.zero = true

    elseif a == "-f" or a == "--skip-fields" then
        i = i + 1
        opts.skip_fields = tonumber(arg[i]) or 0

    elseif a == "-s" or a == "--skip-chars" then
        i = i + 1
        opts.skip_chars = tonumber(arg[i]) or 0

    elseif a == "-w" or a == "--check-chars" then
        i = i + 1
        opts.check_chars = tonumber(arg[i])

    else
        files[#files+1] = a
    end

    i = i + 1
end


if #files == 0 then
    files[1] = "-"
end

local function compare_key(line)

    if opts.skip_fields > 0 then

        local skipped = 0
        local pos = 1

        while skipped < opts.skip_fields do

            local a,b = line:find("%s+%S+", pos)

            if not a then
                pos = #line + 1
                break
            end

            pos = b + 1
            skipped = skipped + 1
        end

        line = line:sub(pos)
    end


    if opts.skip_chars > 0 then
        line = line:sub(opts.skip_chars + 1)
    end


    if opts.check_chars then
        line = line:sub(1, opts.check_chars)
    end


    if opts.ignore_case then
        line = line:lower()
    end


    return line
end


local function read_input(file)

    local lines = {}

    local f

    if file == "-" then
        f = io.stdin
    else
        f = io.open(file,"rb")

        if not f then
            io.stderr:write(
                "uniq: cannot read '",
                file,
                "'\n"
            )
            return lines
        end
    end


    for line in f:lines() do
        lines[#lines+1] = line
    end


    if f ~= io.stdin then
        f:close()
    end

    return lines
end


local lines = read_input(files[1])

local groups = {}

local current = nil
local count = 0


local function flush()

    if not current then
        return
    end


    if opts.count then

        print(string.format("%7d %s", count, current))

    elseif opts.repeated then

        if count > 1 then
            print(current)
        end

    elseif opts.all_repeated then

        if count > 1 then
            for _ = 1,count do
                print(current)
            end
        end

    elseif opts.unique then

        if count == 1 then
            print(current)
        end

    else

        print(current)

    end
end


for _,line in ipairs(lines) do

    local key = compare_key(line)


    if current == nil then

        current = line
        current_key = key
        count = 1


    elseif key == current_key then

        count = count + 1


    else

        flush()

        current = line
        current_key = key
        count = 1

    end
end


flush()
