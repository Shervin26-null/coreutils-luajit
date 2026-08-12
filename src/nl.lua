local VERSION = "luajit-coreutils nl 0.1"

local opts = {
    body = "t",
    width = 6,
    sep = "\t",
    start = 1,
    increment = 1,
    format = "rn",
    no_renumber = false,
    delimiter = "\\:",
}

local files = {}

local args = {...}

local i = 1
while i <= #args do
    local a = args[i]

    if a == "-b" then
        i=i+1
        opts.body=args[i]

    elseif a:sub(1,2) == "-b" then
        opts.body=a:sub(3)

    elseif a == "-w" then
        i=i+1
        opts.width=tonumber(args[i])

    elseif a:sub(1,2) == "-w" then
        opts.width=tonumber(a:sub(3))

    elseif a == "-v" then
        i=i+1
        opts.start=tonumber(args[i])

    elseif a:sub(1,2) == "-v" then
        opts.start=tonumber(a:sub(3))

    elseif a == "-i" then
        i=i+1
        opts.increment=tonumber(args[i])

    elseif a:sub(1,2) == "-i" then
        opts.increment=tonumber(a:sub(3))

    elseif a == "-l" then
        i=i+1
        opts.join=tonumber(args[i])

    elseif a:sub(1,2) == "-l" then
        opts.join=tonumber(a:sub(3))


    elseif a == "-w" then
        i=i+1
        opts.width=tonumber(args[i])

    elseif a:sub(1,2) == "-w" then
        opts.width=tonumber(a:sub(3))

    elseif a == "-s" then
        i=i+1
        opts.sep=args[i]

    elseif a:sub(1,2) == "-s" then
        opts.sep=a:sub(3)

    elseif a == "-n" then
        i=i+1
        opts.format=args[i]

    elseif a:sub(1,2) == "-n" then
        opts.format=a:sub(3)

    elseif a == "-p" then
        opts.no_renumber = true

    elseif a == "-d" then
        i=i+1
        opts.delimiter=args[i]

    elseif a:sub(1,2) == "-d" then
        opts.delimiter=a:sub(3)

    elseif a == "--version" then
        print(VERSION)
        os.exit()

    elseif a == "--help" then
        print("Usage: nl [OPTION]... [FILE]...")
        os.exit()

    else
        files[#files+1]=a
    end

    i=i+1
end

if #files == 0 then
    files[1]="-"
end

local function format_number(n)
    local s = tostring(n)

    if opts.format == "rz" then
        return string.rep("0", math.max(0, opts.width - #s)) .. s

    elseif opts.format == "ln" then
        return s .. string.rep(" ", math.max(0, opts.width - #s))

    else
        return string.rep(" ", math.max(0, opts.width - #s)) .. s
    end
end


local number = opts.start

local function process(stream)
    local blanks = 0

    for line in stream:lines() do

        if line == "" then
            blanks = blanks + 1

            if opts.join and blanks < opts.join then
                io.write("\n")
                goto continue
            end
        else
            blanks = 0
        end

        local add = false

        if opts.body == "a" then
            add = true

        elseif opts.body == "t" then
            if line ~= "" then
                add = true
            end
        end

        if add then
            io.write(
                format_number(number),
                opts.sep,
                line,
                "\n"
            )

            number = number + opts.increment

        else
            io.write(line, "\n")
        end

        ::continue::

    end
end



local status = 0

for _, file in ipairs(files) do

    if file == "-" then

        process(io.stdin)

    else

        local f, err = io.open(file, "r")

        if not f then
            io.stderr:write(
                "nl: ",
                err,
                "\n"
            )

            status = 1

        else
            process(f)
            f:close()
        end

    end

end

os.exit(status)
