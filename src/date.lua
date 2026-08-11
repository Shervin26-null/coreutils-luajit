local VERSION = "luajit-coreutils date 0.1"

local utc = false
local format = nil
local iso = false
local rfc = false
local rfc3339 = false

local function help()
print([[
Usage: date [OPTION]... [+FORMAT]

Display the current time.

  -u, --utc
         print UTC time

      --help
         display this help and exit
      --version
         output version information
]])
end


for _,a in ipairs(arg) do

    if a == "--help" then
        help()
        os.exit(0)

    elseif a == "--version" then
        print(VERSION)
        os.exit(0)

    elseif a == "-u" or a == "--utc" then
        utc = true

    elseif a == "-I" or a == "--iso-8601" then
        iso = true

    elseif a == "-R" or a == "--rfc-email" then
        rfc = true

    elseif a == "--rfc-3339" then
        rfc3339 = true

    elseif a:sub(1,1) == "+" then
        format = a:sub(2)
    end
end


local t

if utc then
    t = os.date("!*t")
else
    t = os.date("*t")
end


if iso then
    print(string.format("%04d-%02d-%02d",
        t.year, t.month, t.day))
    os.exit(0)
end

if rfc then
    print(os.date(utc and "!%a, %d %b %Y %H:%M:%S +0000"
                     or "%a, %d %b %Y %H:%M:%S %z"))
    os.exit(0)
end

if rfc3339 then
    print(string.format("%04d-%02d-%02dT%02d:%02d:%02d",
        t.year, t.month, t.day,
        t.hour, t.min, t.sec))
    os.exit(0)
end

if format then

    local out = format

    out = out:gsub("%%Y", string.format("%04d", t.year))
    out = out:gsub("%%y", string.format("%02d", t.year % 100))
    out = out:gsub("%%m", string.format("%02d", t.month))
    out = out:gsub("%%d", string.format("%02d", t.day))
    out = out:gsub("%%e", tostring(t.day))
    out = out:gsub("%%H", string.format("%02d", t.hour))
    out = out:gsub("%%I", string.format("%02d", ((t.hour - 1) % 12) + 1))
    out = out:gsub("%%M", string.format("%02d", t.min))
    out = out:gsub("%%S", string.format("%02d", t.sec))

    out = out:gsub("%%F",
        string.format("%04d-%02d-%02d", t.year, t.month, t.day))

    out = out:gsub("%%T",
        string.format("%02d:%02d:%02d", t.hour, t.min, t.sec))

    out = out:gsub("%%a", os.date("%a", os.time(t)))
    out = out:gsub("%%A", os.date("%A", os.time(t)))
    out = out:gsub("%%b", os.date("%b", os.time(t)))
    out = out:gsub("%%B", os.date("%B", os.time(t)))

    out = out:gsub("%%s", tostring(os.time(t)))

    print(out)

else

    print(os.date(utc and "!%a %b %d %H:%M:%S UTC %Y"
                       or "%a %b %d %H:%M:%S %Z %Y"))

end
