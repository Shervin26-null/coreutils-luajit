#!/usr/bin/env luajit

local ffi = require("ffi")
local bit = require("bit")
local C = ffi.C

ffi.cdef[[
int chmod(const char *path, unsigned int mode);
int stat(const char *path, void *buf);
void *opendir(const char *name);
void *readdir(void *dirp);
int closedir(void *dirp);
]]

local VERSION = "luajit-coreutils chmod 0.1"

local verbose = false
local changes = false
local recursive = false
local reference = nil
local mode_arg
local files = {}

local function die(msg)
    io.stderr:write("chmod: ", msg, "\n")
    os.exit(1)
end


-- Linux stat layout independent mode extraction.
-- mode_t is always located at offset 24 on Linux ABIs.
local function get_mode(path)

    local f = io.popen("stat -c %a " .. string.format("%q", path))

    if not f then
        die("cannot read mode of '" .. path .. "'")
    end

    local out = f:read("*a")
    f:close()

    out = out:gsub("%s+", "")

    local mode = tonumber(out, 8)

    if not mode then
        die("cannot read mode of '" .. path .. "'")
    end

    return mode
end


local function parse_octal(s)

    if s:match("^0?[0-7]+$") then
        return tonumber(s, 8)
    end

    return nil
end

local function symbolic(expr, old)

    local mode = old

    for rule in expr:gmatch("[^,]+") do

        local who, op, perms =
            rule:match("^([ugoa]*)([+-=])([rwxst]*)$")

        if not op then
            die("invalid mode: '"..expr.."'")
        end


        if who == "" then
            who = "a"
        end


        local add = 0

        if perms:find("r") then
            if who:find("u") or who=="a" then add=bit.bor(add,256) end
            if who:find("g") or who=="a" then add=bit.bor(add,32) end
            if who:find("o") or who=="a" then add=bit.bor(add,4) end
        end


        if perms:find("w") then
            if who:find("u") or who=="a" then add=bit.bor(add,128) end
            if who:find("g") or who=="a" then add=bit.bor(add,16) end
            if who:find("o") or who=="a" then add=bit.bor(add,2) end
        end


        if perms:find("x") then
            if who:find("u") or who=="a" then add=bit.bor(add,64) end
            if who:find("g") or who=="a" then add=bit.bor(add,8) end
            if who:find("o") or who=="a" then add=bit.bor(add,1) end
        end

        if perms:find("s") then
            if who:find("u") then add=bit.bor(add,2048) end
            if who:find("g") then add=bit.bor(add,1024) end
        end

        if perms:find("t") then
            if who:find("o") or who=="a" then add=bit.bor(add,512) end
        end

        if perms:find("s") then
            if who:find("u") then add=bit.bor(add,2048) end
            if who:find("g") then add=bit.bor(add,1024) end
        end

        if perms:find("t") then
            if who:find("o") or who=="a" then add=bit.bor(add,512) end
        end


        if op == "+" then

            mode = bit.bor(mode, add)

        elseif op == "-" then

            mode = bit.band(mode, bit.bnot(add))

        elseif op == "=" then

            local clear = 0

            if who:find("u") or who=="a" then
                clear=bit.bor(clear,448)
            end

            if who:find("g") or who=="a" then
                clear=bit.bor(clear,56)
            end

            if who:find("o") or who=="a" then
                clear=bit.bor(clear,7)
            end

            mode = bit.bor(bit.band(mode,bit.bnot(clear)),add)

        end
    end

    return mode
end



for _,a in ipairs(arg) do

    if a=="--version" then
        print(VERSION)
        os.exit(0)

    elseif a=="--help" then
        print([[
Usage: chmod [OPTION]... MODE FILE...
  or:  chmod [OPTION]... OCTAL-MODE FILE...
  or:  chmod [OPTION]... --reference=RFILE FILE...

Change the permissions of each FILE.

Options:
  -c, --changes
         report only when a change is made
  -R, --recursive
         change files and directories recursively
  -v, --verbose
         output a diagnostic for every file processed
      --reference=RFILE
         use RFILE's mode instead of MODE

      --help
         display this help and exit
      --version
         output version information and exit

MODE:
  Octal modes:
    755, 0644, etc.

  Symbolic modes:
    [ugoa]*([-+=][rwxst]*)

Permission bits:
  r  read
  w  write
  x  execute
  s  set-user-ID/set-group-ID
  t  sticky bit
]])
        os.exit(0)

    elseif a=="-v" or a=="--verbose" then
        verbose=true

    elseif a=="-c" or a=="--changes" then
        changes=true

    elseif a=="-R" or a=="--recursive" then
        recursive=true

    elseif a:match("^%-%-reference=") then
        reference=a:match("^%-%-reference=(.*)")

    elseif a:match("^%-%-reference=") then
        reference=a:match("^%-%-reference=(.*)")

    elseif not mode_arg and not reference then
        mode_arg=parse_octal(a) or a

    else
        files[#files+1]=a
    end

end


if (not mode_arg and not reference) or #files==0 then
    die("missing operand")
end




local function is_dir(path)
    local d = C.opendir(path)

    if d ~= nil then
        C.closedir(d)
        return true
    end

    return false
end


local function chmod_recursive(path, fn)

    fn(path)

    if not is_dir(path) then
        return
    end

    local dir = C.opendir(path)

    if dir == nil then
        return
    end

    while true do
        local ent = C.readdir(dir)

        if ent == nil then
            break
        end

        local name = ffi.string(ffi.cast("char *", ent) + 19)

        if name ~= "." and name ~= ".." then
            chmod_recursive(path .. "/" .. name, fn)
        end
    end

    C.closedir(dir)
end

local function apply(path)

    local old=get_mode(path)

    local new

    if reference then
        new=get_mode(reference)
    elseif type(mode_arg)=="number" then
        new=mode_arg
    else
        new=symbolic(mode_arg,old)
    end

    if C.chmod(path,new) ~= 0 then
        die("changing permissions of '"..path.."' failed")
    end

    if verbose or (changes and old ~= new) then
        io.write("mode of '",path,"' changed\n")
    end
end


for _,file in ipairs(files) do

    if recursive then
        chmod_recursive(file, apply)
    else
        apply(file)
    end

end
