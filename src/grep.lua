local VERSION = "luajit-coreutils grep 0.1"

local opts = {
    ignore_case = false,
    invert = false,
    line_number = false,
    count = false,
    files_with_matches = false,
    quiet = false,
    whole_line = false,
    word = false,
    regex = false,
    patterns = {},
    filename = false,
    no_filename = false,
    only_matching = false,
    max_count = nil,
    color = nil,
    recursive = false,
    follow_links = false,
    include = nil,
    exclude = nil,
    exclude_dir = nil,
    before = 0,
    after = 0,
    context = 0,
    quiet = false,
    color = false,
    files_with_matches = false,
    files_without_match = false,
    null = false,
}

local pattern = nil
local files = {}

local function help()
print([[
Usage: grep [OPTION]... PATTERNS [FILE]...

Pattern selection:
  -i, --ignore-case
  -v, --invert-match
  -x, --line-regexp
  -w, --word-regexp

Output control:
  -n, --line-number
  -c, --count
  -l, --files-with-matches
  -q, --quiet

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

    elseif a == "-i" or a == "--ignore-case" then
        opts.ignore_case = true

    elseif a == "-v" or a == "--invert-match" then
        opts.invert = true

    elseif a == "-n" or a == "--line-number" then
        opts.line_number = true

    elseif a == "-c" or a == "--count" then
        opts.count = true

    elseif a == "-l" or a == "--files-with-matches" then
        opts.files_with_matches = true

    elseif a == "-q" or a == "--quiet" then
        opts.quiet = true

    elseif a == "--color" or a == "--colour" then
        opts.color = true

    elseif a == "-x" or a == "--line-regexp" then
        opts.whole_line = true

    elseif a == "-w" or a == "--word-regexp" then
        opts.word = true

    elseif a == "-H" or a == "--with-filename" then
        opts.filename = true

    elseif a == "-h" or a == "--no-filename" then
        opts.no_filename = true

    elseif a == "-o" or a == "--only-matching" then
        opts.only_matching = true

    elseif a == "--color" or a == "--colour" then
        opts.color = true

    elseif a:match("^%-%-color=") or a:match("^%-%-colour=") then
        local mode = a:match("=(.*)")
        opts.color = mode ~= "never"

    elseif a == "-m" or a == "--max-count" then
        i = i + 1
        opts.max_count = tonumber(arg[i])

    elseif a == "-r" or a == "--recursive" then
        opts.recursive = true

    elseif a == "-q" or a == "--quiet" or a == "--silent" then
        opts.quiet = true

    elseif a == "-l" or a == "--files-with-matches" then
        opts.files_with_matches = true

    elseif a == "-L" or a == "--files-without-match" then
        opts.files_without_match = true

    elseif a == "-Z" or a == "--null" then
        opts.null = true

    elseif a == "-A" or a == "--after-context" then
        i = i + 1
        opts.after = tonumber(arg[i]) or 0

    elseif a == "-B" or a == "--before-context" then
        i = i + 1
        opts.before = tonumber(arg[i]) or 0

    elseif a == "-C" or a == "--context" then
        i = i + 1
        opts.context = tonumber(arg[i]) or 0
        opts.before = opts.context
        opts.after = opts.context

    elseif a == "-R" or a == "--dereference-recursive" then
        opts.recursive = true
        opts.follow_links = true

    elseif a:match("^%-%-include=") then
        opts.include = a:sub(11)

    elseif a:match("^%-%-exclude=") then
        opts.exclude = a:sub(11)

    elseif a:match("^%-%-exclude-dir=") then
        opts.exclude_dir = a:sub(16)

    elseif a == "-E" or a == "--extended-regexp" then
        opts.regex = true

    elseif a == "-e" or a == "--regexp" then
        i = i + 1
        opts.patterns[#opts.patterns+1] = arg[i]

    elseif a == "-f" or a == "--file" then
        i = i + 1
        local f = io.open(arg[i], "r")
        if f then
            for p in f:lines() do
                opts.patterns[#opts.patterns+1] = p
            end
            f:close()
        end

    elseif not pattern then
        pattern = a

    else
        files[#files+1] = a
    end

    i = i + 1
end

if #opts.patterns == 0 then
    if not pattern then
        io.stderr:write("grep: missing pattern\n")
        os.exit(2)
    end
    opts.patterns[1] = pattern
end


if #files == 0 then
    files[1] = "-"
end


local found = false

local ffi = require("ffi")

ffi.cdef[[
int isatty(int fd);
]]

if opts.color == nil then
    opts.color = ffi.C.isatty(1) == 1
end


local function match_line(line)

    local text = line

    if opts.ignore_case then
        text = text:lower()
    end

    for _, pat in ipairs(opts.patterns) do

        local p = pat

        if opts.ignore_case then
            p = p:lower()
        end

        local ok

        if opts.whole_line then
            ok = text == p

        elseif opts.regex then
            ok = text:match(p) ~= nil

        elseif opts.word then
            ok = text:match("%f[%w]" .. p .. "%f[%W]") ~= nil

        else
            ok = text:find(p, 1, true) ~= nil
        end

        if ok then
            return true
        end
    end

    return false
end


local function process(file)

    local f

    if file == "-" then
        f = io.stdin
    else
        f = io.open(file,"r")
        if not f then
            return
        end
    end

    local lines = {}

    for line in f:lines() do
        lines[#lines+1] = line
    end

    if f ~= io.stdin then
        f:close()
    end

    local count = 0
    local any = false
    local printed = {}

    for line_no, line in ipairs(lines) do

        local ok = match_line(line)

        if opts.invert then
            ok = not ok
        end

        if ok then
            any = true
            found = true
            count = count + 1

            if opts.quiet then
                os.exit(0)
            end

            if not opts.count and not opts.files_with_matches then

                local start = math.max(1, line_no - opts.before)
                local finish = math.min(#lines, line_no + opts.after)

                for n = start, finish do
                    if not printed[n] then
                        printed[n] = true

                        local prefix = ""

                        if opts.filename or opts.recursive or (#files > 1 and not opts.no_filename) then
                            prefix = file .. ":"
                        end

                        if opts.line_number then
                            if n == line_no then
                                prefix = prefix .. n .. ":"
                            else
                                prefix = prefix .. n .. "-"
                            end
                        end

                        local out = lines[n]

                        if opts.color and match_line(out) then
                            out = out:gsub(pattern, "\27[01;31m%0\27[0m")
                        end

                        print(prefix .. out)
                    end
                end
            end
        end
    end

    if opts.count then
        print(count)
    end

    if opts.files_with_matches and any then
        print(file)
    end

    if opts.files_without_match and not any then
        print(file)
    end
end


local function glob_match(name, glob)
    if not glob then
        return false
    end

    local pat = glob
        :gsub("%.", "%%.")
        :gsub("%*", ".*")

    return name:match("^" .. pat .. "$") ~= nil
end


local function walk(path)
    local p = io.popen("find " .. string.format("%q", path) .. " -type f")

    if not p then
        return
    end

    for file in p:lines() do
        local name = file:match("([^/]+)$")

        if not opts.include or glob_match(name, opts.include) then
            if not opts.exclude or not glob_match(name, opts.exclude) then
                process(file)
            end
        end
    end

    p:close()
end


for _,file in ipairs(files) do
    if opts.recursive then
        walk(file)
    else
        process(file)
    end
end


if found then
    os.exit(0)
else
    os.exit(1)
end
