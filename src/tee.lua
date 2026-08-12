local VERSION = "luajit-coreutils tee 0.1"

local append = false
local ignore_interrupts = false
local pipe_mode = false
local output_error = nil
local touch_files = false
local make_dirs = false
local files = {}

local args = {...}
local i = 1

while i <= #args do
    local a = args[i]

    if a == "-a" or a == "--append" then
        append = true

    elseif a == "-i" or a == "--ignore-interrupts" then
        ignore_interrupts = true

    elseif a == "-p" then
        pipe_mode = true

    elseif a == "--touch" then
        touch_files = true

    elseif a == "--mkdir" then
        make_dirs = true

    elseif a == "--output-error" then
        i = i + 1
        output_error = args[i]

    elseif a:sub(1,15) == "--output-error=" then
        output_error = a:sub(16)

    elseif a == "--version" then
        print(VERSION)
        os.exit(0)

    elseif a == "--help" then
        print([[
Usage: tee [OPTION]... [FILE]...

Copy standard input to each FILE, and also to standard output.

  -a, --append              append to FILEs instead of overwriting
  -i, --ignore-interrupts   ignore interrupt signals
  -p                        diagnose errors writing to pipes
      --output-error=MODE   set behavior on write error
      --help
      --version
]])
        os.exit(0)

    else
        files[#files + 1] = a
    end

    i = i + 1
end


local outputs = {}

for _, path in ipairs(files) do

    if make_dirs then
        local dir = path:match("(.+)/[^/]+$")
        if dir then
            os.execute("mkdir -p " .. string.format("%q", dir))
        end
    end

    if touch_files then
        local f = io.open(path, "a")
        if f then
            f:close()
        end
    end

    local mode = append and "a" or "w"

    local f, err = io.open(path, mode)

    if not f then
        io.stderr:write("tee: ", path, ": ", err, "\n")

        if output_error == "exit" then
            os.exit(1)
        end

    else
        outputs[#outputs + 1] = {
            file = f,
            name = path
        }
    end
end


for line in io.stdin:lines() do
    local data = line .. "\n"

    io.write(data)
    io.stdout:flush()

    for _, out in ipairs(outputs) do
        local ok, err = out.file:write(data)

        if not ok then
            io.stderr:write(
                "tee: ",
                out.name,
                ": ",
                err,
                "\n"
            )

            if output_error == "exit" then
                os.exit(1)
            end
        end

        out.file:flush()
    end
end


for _, out in ipairs(outputs) do
    out.file:close()
end
