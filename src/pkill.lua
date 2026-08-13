local ffi = require("ffi")

local VERSION = "pkill (coreutils-luajit) 0.1"

ffi.cdef[[
typedef int pid_t;

typedef struct DIR DIR;

struct dirent {
    unsigned long d_ino;
    long d_off;
    unsigned short d_reclen;
    unsigned char d_type;
    char d_name[256];
};

DIR *opendir(const char *name);
struct dirent *readdir(DIR *dirp);
int closedir(DIR *dirp);

int kill(pid_t pid, int sig);
]]

local C = ffi.C

local signal = 15
local echo = false
local count = false
local full = false
local exact = false
local ignore_case = false
local pattern = nil
local user = nil
local parent = nil

local function help()
print([[
Usage: pkill [OPTION]... PATTERN

Options:
 -<sig>, --signal <sig>   signal to send
 -e, --echo               display killed processes
 -c, --count              count matches
 -f, --full               match full command line
 -x, --exact              exact match
 -i, --ignore-case        ignore case
 -u, --euid ID            match effective user
 -P, --parent PID         match parent PID
 -q, --quiet              no output
     --help
     --version
]])
end

local function read(path)
    local f = io.open(path, "rb")
    if not f then
        return nil
    end

    local s = f:read("*a")
    f:close()

    return s
end

local function signal_number(s)
    local sig = {
        HUP=1,
        INT=2,
        QUIT=3,
        KILL=9,
        STOP=19,
        CONT=18,
        TERM=15
    }

    return tonumber(s) or sig[s:upper()] or 15
end

local function lower(s)
    return s:lower()
end

local function get_value(pid, key)
    local data = read("/proc/"..pid.."/status")
    if not data then
        return nil
    end

    return data:match(key..":%s+(%d+)")
end


local i=1
while i<=#arg do

    local a=arg[i]

    if a=="--help" or a=="-h" then
        help()
        os.exit(0)

    elseif a=="--version" or a=="-V" then
        print(VERSION)
        os.exit(0)

    elseif a=="-e" then
        echo=true

    elseif a=="-c" then
        count=true

    elseif a=="-f" then
        full=true

    elseif a=="-x" then
        exact=true

    elseif a=="-i" then
        ignore_case=true

    elseif a=="-q" then
        echo=false

    elseif a=="-u" then
        i=i+1
        user=arg[i]

    elseif a=="-P" then
        i=i+1
        parent=arg[i]

    elseif a=="--signal" then
        i=i+1
        signal=signal_number(arg[i])

    elseif a:match("^%-%-signal=") then
        signal=signal_number(a:match("=(.*)"))

    elseif a:match("^%-[0-9]+$") then
        signal=tonumber(a:sub(2))

    elseif not pattern then
        pattern=a
    end

    i=i+1
end


if not pattern then
    io.stderr:write("pkill: missing pattern\n")
    os.exit(1)
end


local found=0


for pid in io.popen("ls /proc"):lines() do

    if pid:match("^%d+$") then

        if (not user or get_value(pid,"Uid")==user)
        and (not parent or get_value(pid,"PPid")==parent) then

            local name

            if full then
                name=read("/proc/"..pid.."/cmdline")
                if name then
                    name=name:gsub("\0"," ")
                end
            else
                name=read("/proc/"..pid.."/comm")
            end


            if name then

                name=name:gsub("%s+$","")

                local a=name
                local b=pattern

                if ignore_case then
                    a=lower(a)
                    b=lower(b)
                end

                local match

                if exact then
                    match=a==b
                else
                    match=a:find(b,1,true)~=nil
                end


                if match then

                    found=found+1

                    if not count then

                        if echo then
                            print(name.." ("..pid..")")
                        end

                        C.kill(tonumber(pid),signal)
                    end
                end
            end
        end
    end
end


if count then
    print(found)
end


if found>0 then
    os.exit(0)
else
    os.exit(1)
end
