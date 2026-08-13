local ffi = require("ffi")

local VERSION = "sync (coreutils-luajit) 0.1"

ffi.cdef[[
void sync(void);
int syncfs(int fd);
int open(const char *pathname, int flags);
int close(int fd);
]]

local C = ffi.C

local data_only = false
local file_system = false
local files = {}

for _, a in ipairs({...}) do
    if a == "--help" then
        print([[
Usage: sync [OPTION] [FILE]...
Synchronize cached writes to persistent storage

  -d, --data             sync only file data, no unneeded metadata
  -f, --file-system      sync the file systems that contain the files

      --help             display this help and exit
      --version          output version information and exit
]])
        os.exit(0)

    elseif a == "--version" then
        print(VERSION)
        os.exit(0)

    elseif a == "-d" or a == "--data" then
        data_only = true

    elseif a == "-f" or a == "--file-system" then
        file_system = true

    else
        files[#files+1] = a
    end
end


-- no files: sync everything
if #files == 0 then
    if data_only or file_system then
        if data_only then
            io.stderr:write("sync: --data needs at least one argument\\n")
        else
            io.stderr:write("sync: --file-system needs at least one argument\\n")
        end
        os.exit(1)
    end

    C.sync()
    return
end


-- sync requested filesystems
for _, path in ipairs(files) do
    local fd = C.open(path, 0)

    if fd >= 0 then
        if file_system then
            C.syncfs(fd)
        else
            -- Linux has no portable fdatasync declaration here,
            -- fallback to syncing filesystem
            C.sync()
        end

        C.close(fd)
    else
        io.stderr:write("sync: cannot open '", path, "'\n")
    end
end
