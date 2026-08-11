local VERSION = "luajit-coreutils cut 0.1"

local opts = {
    bytes = nil,
    chars = nil,
    fields = nil,
    delimiter = "\t",
    output_delimiter = nil,
    complement = false,
    only_delimited = false,
    zero = false,
    whitespace = false,
    trim = false,
    no_partial = false,
}

local files = {}

local function help()
print([[
Usage: cut OPTION... [FILE]...

Print selected parts of lines from each FILE to standard output.

With no FILE, or when FILE is -, read standard input.

  -b, --bytes=LIST
         select only these byte positions
  -c, --characters=LIST
         select only these character positions
      --complement
         complement selected bytes, characters or fields
  -d, --delimiter=DELIM
         use DELIM instead of TAB
  -f, --fields=LIST
         select only these fields
  -F LIST
         like -f, whitespace mode
  -n, --no-partial
         don't output partial multibyte characters
  -O, --output-delimiter=STRING
         use STRING as output delimiter
  -s, --only-delimited
         do not print non-delimited lines
  -w, --whitespace-delimited
         use whitespace as delimiter
  -z, --zero-terminated
         use NUL as line delimiter

      --help
      --version

LIST ranges:
  N
  N-
  N-M
  -M
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

    elseif a == "-b" or a == "--bytes" then
        i = i + 1
        opts.bytes = arg[i]

    elseif a == "-c" or a == "--characters" then
        i = i + 1
        opts.chars = arg[i]

    elseif a == "-f" or a == "--fields" then
        i = i + 1
        opts.fields = arg[i]

    elseif a == "-d" or a == "--delimiter" then
        i = i + 1
        opts.delimiter = arg[i]

    elseif a == "-O" or a == "--output-delimiter" then
        i = i + 1
        opts.output_delimiter = arg[i]

    elseif a == "--complement" then
        opts.complement = true

    elseif a == "-s" or a == "--only-delimited" then
        opts.only_delimited = true

    elseif a == "-z" or a == "--zero-terminated" then
        opts.zero = true

    elseif a == "-w" or a == "--whitespace-delimited" then
        opts.whitespace = true

    elseif a == "-n" or a == "--no-partial" then
        opts.no_partial = true

    elseif a == "-F" then
        i = i + 1
        opts.fields = arg[i]
        opts.whitespace = true
        opts.output_delimiter = " "

    else
        files[#files + 1] = a
    end

    i = i + 1
end


local modes = 0

if opts.bytes then modes = modes + 1 end
if opts.chars then modes = modes + 1 end
if opts.fields then modes = modes + 1 end

if modes ~= 1 then
    if modes == 0 then
        io.stderr:write("cut: you must specify a list of bytes, characters, or fields\n")
    else
        io.stderr:write("cut: only one of -b, -c, -f may be specified\n")
    end
    os.exit(1)
end


if #files == 0 then
    files[1] = "-"
end

local function parse_list(list, max)

    local selected = {}

    for part in list:gmatch("[^,]+") do

        local a,b = part:match("^(%d+)%-(%d+)$")

        if a then
            a = tonumber(a)
            b = tonumber(b)

            for n = a,b do
                selected[n] = true
            end

        else

            a = part:match("^(%d+)%-$")

            if a then
                a = tonumber(a)

                for n = a,max do
                    selected[n] = true
                end

            else

                b = part:match("^%-(%d+)$")

                if b then
                    b = tonumber(b)

                    for n = 1,b do
                        selected[n] = true
                    end

                else

                    selected[tonumber(part)] = true

                end
            end
        end
    end

    return selected
end


local function cut_chars(line, list)

    local chars = {}

    for c in line:gmatch(".") do
        chars[#chars+1] = c
    end

    local sel = parse_list(list, #chars)
    local out = {}

    for i = 1,#chars do

        local take = sel[i]

        if opts.complement then
            take = not take
        end

        if take then
            out[#out+1] = chars[i]
        end
    end

    return table.concat(out)
end


local function cut_bytes(line, list)

    local bytes = {}

    for i = 1,#line do
        bytes[i] = line:sub(i,i)
    end

    local sel = parse_list(list,#bytes)
    local out = {}

    for i = 1,#bytes do

        local take = sel[i]

        if opts.complement then
            take = not take
        end

        if take then
            out[#out+1] = bytes[i]
        end
    end

    return table.concat(out)
end


local function cut_fields(line,list)

    local delim = opts.delimiter
    local fields = {}

    if opts.whitespace then

        for f in line:gmatch("%S+") do
            fields[#fields+1] = f
        end

    else

        local start = 1

        while true do
            local pos = line:find(delim, start, true)

            if not pos then
                fields[#fields+1] = line:sub(start)
                break
            end

            fields[#fields+1] = line:sub(start, pos - 1)
            start = pos + #delim
        end

    end


    local has_delim

    if opts.whitespace then
        has_delim = line:match("%s+") ~= nil
    else
        has_delim = line:find(delim, 1, true) ~= nil
    end

    if not has_delim and opts.only_delimited then
        return ""
    end

    if not has_delim and not opts.only_delimited then
        return line
    end


    local sel = parse_list(list, #fields)
    local out = {}
    local sep = opts.output_delimiter or delim


    for i = 1, #fields do

        local take = sel[i]

        if opts.complement then
            take = not take
        end

        if take then
            out[#out+1] = fields[i]
        end

    end


    return table.concat(out, sep)
end

local function process(line)

    if opts.bytes then
        return cut_bytes(line,opts.bytes)

    elseif opts.chars then
        return cut_chars(line,opts.chars)

    else
        return cut_fields(line,opts.fields)

    end
end


local separator = "\n"

if opts.zero then
    separator = "\0"
end


for _,file in ipairs(files) do

    local handle

    if file == "-" then
        handle = io.stdin
    else
        handle = io.open(file,"rb")

        if not handle then
            io.stderr:write(
                "cut: cannot open '",
                file,
                "'\n"
            )
        end
    end


    if handle then

        for line in handle:lines() do

            io.write(process(line))
            io.write(separator)

        end

        if handle ~= io.stdin then
            handle:close()
        end

    end
end
