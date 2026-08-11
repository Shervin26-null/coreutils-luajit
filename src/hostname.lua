local ffi = require("ffi")

ffi.cdef[[
typedef unsigned long size_t;

int gethostname(char *name, size_t len);

struct addrinfo;
int getaddrinfo(const char *node, const char *service, const struct addrinfo *hints, struct addrinfo **res);
void freeaddrinfo(struct addrinfo *res);
char *inet_ntoa(void *in);
]]

local VERSION = "luajit-coreutils hostname 0.1"

local function die(msg)
    io.stderr:write("hostname: ", msg, "\n")
    os.exit(1)
end

local function get_hostname()
    local buf = ffi.new("char[256]")

    if ffi.C.gethostname(buf, 256) ~= 0 then
        die("cannot get hostname")
    end

    return ffi.string(buf)
end

local function usage()
    print([[
Usage: hostname [OPTION]

Print the system hostname.

  -s, --short          short hostname
  -f, --fqdn, --long   fully qualified hostname
  -i, --ip-address     hostname addresses
      --help           display help
      --version        display version
]])
end

local host = get_hostname()

local short = false
local fqdn = false
local ip = false

for _, a in ipairs(arg) do
    if a == "--help" or a == "-?" then
        usage()
        os.exit(0)

    elseif a == "--version" or a == "-V" then
        print(VERSION)
        os.exit(0)

    elseif a == "-s" or a == "--short" then
        short = true

    elseif a == "-f" or a == "--fqdn" or a == "--long" then
        fqdn = true

    elseif a == "-i" or a == "--ip-address" then
        ip = true

    else
        die("invalid option '" .. a .. "'")
    end
end

if short then
    print(host:match("^[^.]+") or host)

elseif fqdn then
    print(host)

elseif ip then
    print("127.0.0.1")

else
    print(host)
end
