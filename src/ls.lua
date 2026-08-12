local ffi = require("ffi")

local VERSION = "luajit-coreutils ls 0.1"

-- Define architecture-specific stat structs for Linux
if ffi.arch == "x64" then
    ffi.cdef[[
        struct stat {
            unsigned long st_dev;
            unsigned long st_ino;
            unsigned long st_nlink;
            unsigned int  st_mode;
            unsigned int  st_uid;
            unsigned int  st_gid;
            unsigned int  __pad0;
            unsigned long st_rdev;
            long          st_size;
            long          st_blksize;
            long          st_blocks;
            long          st_atime;
            unsigned long st_atime_nsec;
            long          st_mtime;
            unsigned long st_mtime_nsec;
            long          st_ctime;
            unsigned long st_ctime_nsec;
            long          __unused[3];
        };
    ]]
elseif ffi.arch == "arm64" then
    ffi.cdef[[
        struct stat {
            unsigned long st_dev;
            unsigned long st_ino;
            unsigned int  st_mode;
            unsigned int  st_nlink;
            unsigned int  st_uid;
            unsigned int  st_gid;
            unsigned long st_rdev;
            unsigned long __pad1;
            long          st_size;
            int           st_blksize;
            int           __pad2;
            long          st_blocks;
            long          st_atime;
            unsigned long st_atime_nsec;
            long          st_mtime;
            unsigned long st_mtime_nsec;
            long          st_ctime;
            unsigned long st_ctime_nsec;
            unsigned int  __unused[2];
        };
    ]]
else
    ffi.cdef[[
        struct stat {
            unsigned long st_dev;
            unsigned long st_ino;
            unsigned short st_mode;
            unsigned short st_nlink;
            unsigned short st_uid;
            unsigned short st_gid;
            unsigned long st_rdev;
            unsigned long st_size;
            unsigned long st_blksize;
            unsigned long st_blocks;
            long          st_atime;
            unsigned long st_atime_nsec;
            long          st_mtime;
            unsigned long st_mtime_nsec;
            long          st_ctime;
            unsigned long st_ctime_nsec;
            unsigned long __unused[2];
        };
    ]]
end

ffi.cdef[[
    struct dirent {
        unsigned long d_ino;
        long          d_off;
        unsigned short d_reclen;
        unsigned char  d_type;
        char           d_name[256];
    };

    typedef struct DIR DIR;

    DIR *opendir(const char *name);
    struct dirent *readdir(DIR *dirp);
    int closedir(DIR *dirp);
    int lstat(const char *path, struct stat *buf);
    int stat(const char *path, struct stat *buf);
    int readlink(const char *path, char *buf, size_t bufsiz);

    struct passwd {
        char *pw_name;
        char *pw_passwd;
        unsigned int pw_uid;
        unsigned int pw_gid;
        char *pw_gecos;
        char *pw_dir;
        char *pw_shell;
    };

    struct group {
        char *gr_name;
        char *gr_passwd;
        unsigned int gr_gid;
        char **gr_mem;
    };

    struct passwd *getpwuid(unsigned int uid);
    struct group *getgrgid(unsigned int gid);
    int isatty(int fd);
]]

local C = ffi.C

local S_IFMT   = 0xF000
local S_IFDIR  = 0x4000
local S_IFCHR  = 0x2000
local S_IFBLK  = 0x6000
local S_IFREG  = 0x8000
local S_IFLNK  = 0xA000
local S_IFSOCK = 0xC000
local S_IFIFO  = 0x1000

local opts = {
    all = false,
    almost_all = false,
    long_format = false,
    human_readable = false,
    si = false,
    reverse = false,
    recursive = false,
    directory = false,
    classify = false,
    inode = false,
    size = false,
    one_per_line = false,
    zero = false,
    color = "never",
    sort = "name",
    time = "mtime",
    dereference = false,
    numeric_ids = false,
    no_owner = false,
    no_group = false,
    group_dirs_first = false,
}

local targets = {}

local function help()
print([[
Usage: ls [OPTION]... [FILE]...
List information about the FILEs (the current directory by default).
Sort entries alphabetically if none of -cftuvSUX nor --sort is specified.

  -a, --all                  do not ignore entries starting with .
  -A, --almost-all           do not list implied . and ..
      --color[=WHEN]         color the output WHEN; 'always', 'auto', or 'never'
  -d, --directory            list directories themselves, not their contents
  -F, --classify             append indicator (one of */=>@|) to entries
  -g                         like -l, but do not list owner
  -G, --no-group             in a long listing, don't print group names
  -h, --human-readable       with -l and -s, print sizes like 1K 234M 2G etc.
      --si                   likewise, but use powers of 1000 not 1024
      --group-directories-first
                             group directories before files
  -i, --inode                print the index number of each file
  -l                         use a long listing format
  -L, --dereference          when showing file information for a symbolic link,
                             show information for the file the link references
  -n, --numeric-uid-gid      like -l, but list numeric user and group IDs
  -o                         like -l, but do not list group information
  -r, --reverse              reverse order while sorting
  -R, --recursive            list subdirectories recursively
  -s, --size                 print the allocated size of each file, in blocks
  -S                         sort by file size, largest first
      --sort=WORD            change default 'name' sort to WORD
      --time=WORD            select timestamp: atime, ctime, or mtime (default)
  -t                         sort by time, newest first
  -u                         with -l: show access time; sort by access time
  -U                         do not sort directory entries
  -X                         sort alphabetically by entry extension
      --zero                 end each output line with NUL, not newline
  -1                         list one file per line
      --help                 display this help and exit
      --version              output version information and exit
]])
end

local function parse_args(args)
    local i = 1
    while i <= #args do
        local a = args[i]
        if a == "--help" then
            help()
            os.exit(0)
        elseif a == "--version" then
            print(VERSION)
            os.exit(0)
        elseif a == "--all" then opts.all = true
        elseif a == "--almost-all" then opts.almost_all = true
        elseif a == "--directory" then opts.directory = true
        elseif a == "--classify" then opts.classify = true
        elseif a == "--human-readable" then opts.human_readable = true
        elseif a == "--si" then opts.si = true; opts.human_readable = true
        elseif a == "--inode" then opts.inode = true
        elseif a == "--dereference" then opts.dereference = true
        elseif a == "--numeric-uid-gid" then opts.numeric_ids = true
        elseif a == "--no-group" then opts.no_group = true
        elseif a == "--reverse" then opts.reverse = true
        elseif a == "--recursive" then opts.recursive = true
        elseif a == "--size" then opts.size = true
        elseif a == "--zero" then opts.zero = true
        elseif a == "--group-directories-first" then opts.group_dirs_first = true
        elseif a:sub(1, 7) == "--sort=" then
            opts.sort = a:sub(8)
        elseif a:sub(1, 7) == "--time=" then
            local t = a:sub(8)
            if t == "atime" or t == "access" or t == "use" then opts.time = "atime"
            elseif t == "ctime" or t == "status" then opts.time = "ctime"
            else opts.time = "mtime" end
        elseif a:sub(1, 8) == "--color=" then
            opts.color = a:sub(9)
        elseif a == "--color" then
            opts.color = "always"
        elseif a:sub(1, 2) == "--" and #a > 2 then
            io.stderr:write("ls: unrecognized option '" .. a .. "'\n")
            os.exit(2)
        elseif a:sub(1, 1) == "-" and #a > 1 then
            for j = 2, #a do
                local c = a:sub(j, j)
                if c == "a" then opts.all = true
                elseif c == "A" then opts.almost_all = true
                elseif c == "l" then opts.long_format = true
                elseif c == "d" then opts.directory = true
                elseif c == "F" then opts.classify = true
                elseif c == "h" then opts.human_readable = true
                elseif c == "i" then opts.inode = true
                elseif c == "r" then opts.reverse = true
                elseif c == "R" then opts.recursive = true
                elseif c == "s" then opts.size = true
                elseif c == "1" then opts.one_per_line = true
                elseif c == "S" then opts.sort = "size"
                elseif c == "t" then opts.sort = "time"
                elseif c == "U" then opts.sort = "none"
                elseif c == "X" then opts.sort = "extension"
                elseif c == "L" then opts.dereference = true
                elseif c == "n" then opts.numeric_ids = true
                elseif c == "g" then opts.long_format = true; opts.no_owner = true
                elseif c == "o" then opts.long_format = true; opts.no_group = true
                elseif c == "G" then opts.no_group = true
                elseif c == "u" then opts.time = "atime"
                elseif c == "c" then opts.time = "ctime"
                else
                    io.stderr:write("ls: invalid option -- '" .. c .. "'\n")
                    os.exit(2)
                end
            end
        else
            targets[#targets + 1] = a
        end
        i = i + 1
    end
    if #targets == 0 then targets[1] = "." end
end

parse_args(arg)

local function use_color()
    if opts.color == "always" or opts.color == "yes" or opts.color == "force" then
        return true
    elseif opts.color == "auto" or opts.color == "tty" or opts.color == "if-tty" then
        return C.isatty(1) == 1
    end
    return false
end

local function format_human(size)
    local base = opts.si and 1000 or 1024
    local units = opts.si and {"", "k", "M", "G", "T", "P"} or {"", "K", "M", "G", "T", "P"}
    local i = 1
    local d = tonumber(size)
    while d >= base and i < #units do
        d = d / base
        i = i + 1
    end
    if i == 1 then return string.format("%d", d) end
    if d < 10 then return string.format("%.1f%s", d, units[i]) end
    return string.format("%d%s", math.floor(d + 0.5), units[i])
end

local function get_mode_str(mode)
    local fmt = bit.band(mode, S_IFMT)
    local c = "-"
    if fmt == S_IFDIR then c = "d"
    elseif fmt == S_IFLNK then c = "l"
    elseif fmt == S_IFCHR then c = "c"
    elseif fmt == S_IFBLK then c = "b"
    elseif fmt == S_IFSOCK then c = "s"
    elseif fmt == S_IFIFO then c = "p"
    end

    local chars = {"r", "w", "x", "r", "w", "x", "r", "w", "x"}
    local str = {c}
    for i = 1, 9 do
        local bit_val = bit.lshift(1, 9 - i)
        if bit.band(mode, bit_val) ~= 0 then
            str[#str + 1] = chars[i]
        else
            str[#str + 1] = "-"
        end
    end
    return table.concat(str)
end

local pwd_cache = {}
local function get_owner(uid)
    if opts.numeric_ids then return tostring(uid) end
    if not pwd_cache[uid] then
        local pw = C.getpwuid(uid)
        pwd_cache[uid] = pw ~= nil and ffi.string(pw.pw_name) or tostring(uid)
    end
    return pwd_cache[uid]
end

local grp_cache = {}
local function get_group(gid)
    if opts.numeric_ids then return tostring(gid) end
    if not grp_cache[gid] then
        local gr = C.getgrgid(gid)
        grp_cache[gid] = gr ~= nil and ffi.string(gr.gr_name) or tostring(gid)
    end
    return grp_cache[gid]
end

local current_year = tonumber(os.date("%Y"))
local function format_time(ts)
    local t = tonumber(ts)
    if not t or t <= 0 then return "Jan  1  1970" end
    local year = tonumber(os.date("%Y", t))
    if year == current_year then
        return os.date("%b %e %H:%M", t)
    else
        return os.date("%b %e  %Y", t)
    end
end

local function colorize(name, mode_val)
    if not use_color() then return name end

    local fmt = bit.band(mode_val, S_IFMT)
    local color_code = nil

    if fmt == S_IFDIR then
        color_code = "\27[1;34m" -- Bold Blue
    elseif fmt == S_IFLNK then
        color_code = "\27[1;36m" -- Bold Cyan
    elseif fmt == S_IFSOCK then
        color_code = "\27[1;35m" -- Magenta
    elseif fmt == S_IFIFO then
        color_code = "\27[33m"   -- Yellow
    elseif bit.band(mode_val, 0111) ~= 0 then
        color_code = "\27[1;32m" -- Bold Green
    end

    if color_code then
        return color_code .. name .. "\27[0m"
    end
    return name
end

local function get_file_info(path, name)
    local st = ffi.new("struct stat")
    local res = opts.dereference and C.stat(path, st) or C.lstat(path, st)
    if res ~= 0 then return nil end

    local is_dir = bit.band(st.st_mode, S_IFMT) == S_IFDIR
    local is_link = bit.band(st.st_mode, S_IFMT) == S_IFLNK
    
    local time_val = st.st_mtime
    if opts.time == "atime" then time_val = st.st_atime
    elseif opts.time == "ctime" then time_val = st.st_ctime end

    local link_target = nil
    if is_link and opts.long_format then
        local buf = ffi.new("char[1024]")
        local len = C.readlink(path, buf, 1024)
        if len > 0 then
            link_target = ffi.string(buf, len)
        end
    end

    return {
        name = name or path,
        path = path,
        st_mode = tonumber(st.st_mode),
        is_dir = is_dir,
        is_link = is_link,
        mode_str = get_mode_str(st.st_mode),
        size = tonumber(st.st_size),
        blocks = tonumber(st.st_blocks),
        inode = tonumber(st.st_ino),
        nlink = tonumber(st.st_nlink),
        owner = get_owner(st.st_uid),
        group = get_group(st.st_gid),
        time = tonumber(time_val),
        link_target = link_target
    }
end

local function sort_entries(entries)
    if opts.sort == "none" then return end

    table.sort(entries, function(a, b)
        if type(a) ~= "table" or type(b) ~= "table" then
            return tostring(a) < tostring(b)
        end

        a.name = a.name or ""
        b.name = b.name or ""

        if opts.group_dirs_first then
            if a.is_dir and not b.is_dir then return not opts.reverse end
            if not a.is_dir and b.is_dir then return opts.reverse end
        end

        local cmp = false
        if opts.sort == "size" then
            if a.size == b.size then cmp = a.name < b.name
            else cmp = a.size > b.size end
        elseif opts.sort == "time" then
            if a.time == b.time then cmp = a.name < b.name
            else cmp = a.time > b.time end
        elseif opts.sort == "extension" then
            local ext_a = a.name:match("^.+(%..+)$") or ""
            local ext_b = b.name:match("^.+(%..+)$") or ""
            if ext_a == ext_b then cmp = a.name < b.name
            else cmp = ext_a < ext_b end
        else
            cmp = a.name < b.name
        end

        if opts.reverse then return not cmp else return cmp end
    end)
end

local function print_entries(entries, total_blocks)
    if #entries == 0 then return end

    if opts.long_format and total_blocks then
        print("total " .. (opts.human_readable and format_human(total_blocks * 512) or math.floor(total_blocks / 2)))
    end

    local max_inode, max_nlink, max_owner, max_group, max_size = 0, 0, 0, 0, 0
    for _, e in ipairs(entries) do
        max_inode = math.max(max_inode, #tostring(e.inode))
        max_nlink = math.max(max_nlink, #tostring(e.nlink))
        max_owner = math.max(max_owner, #e.owner)
        max_group = math.max(max_group, #e.group)
        local sz_str = opts.human_readable and format_human(e.size) or tostring(e.size)
        max_size = math.max(max_size, #sz_str)
    end

    local term = opts.zero and "\0" or "\n"

    for _, e in ipairs(entries) do
        local line = {}

        if opts.inode then
            line[#line + 1] = string.format("%" .. max_inode .. "d ", e.inode)
        end

        if opts.size then
            local b_str = opts.human_readable and format_human(e.blocks * 512) or math.floor(e.blocks / 2)
            line[#line + 1] = string.format("%4s ", b_str)
        end

        if opts.long_format then
            line[#line + 1] = e.mode_str .. " "
            line[#line + 1] = string.format("%" .. max_nlink .. "d ", e.nlink)
            if not opts.no_owner then line[#line + 1] = string.format("%-" .. max_owner .. "s ", e.owner) end
            if not opts.no_group then line[#line + 1] = string.format("%-" .. max_group .. "s ", e.group) end
            
            local sz_str = opts.human_readable and format_human(e.size) or tostring(e.size)
            line[#line + 1] = string.format("%" .. max_size .. "s ", sz_str)
            line[#line + 1] = format_time(e.time) .. " "
        end

        local display_name = colorize(e.name, e.st_mode)
        if opts.classify then
            if e.is_dir then display_name = display_name .. "/"
            elseif e.is_link then display_name = display_name .. "@"
            elseif bit.band(e.st_mode, 0111) ~= 0 then display_name = display_name .. "*"
            end
        end

        line[#line + 1] = display_name

        if opts.long_format and e.link_target then
            line[#line + 1] = " -> " .. e.link_target
        end

        io.write(table.concat(line) .. term)
    end
end

local function list_dir(path, print_header)
    local dir = C.opendir(path)
    if dir == nil then
        io.stderr:write("ls: cannot access '" .. path .. "': No such file or directory\n")
        return
    end

    if print_header then
        io.write(path .. ":\n")
    end

    local entries = {}
    local subdirs = {}
    local total_blocks = 0

    while true do
        local ptr = C.readdir(dir)
        if ptr == nil then break end
        local name = ffi.string(ptr.d_name)

        local is_dot = (name == "." or name == "..")
        local is_hidden = name:sub(1, 1) == "."

        local show = false
        if opts.all then
            show = true
        elseif opts.almost_all then
            if not is_dot then show = true end
        else
            if not is_hidden then show = true end
        end

        if show then
            local full_path = path == "." and name or (path .. "/" .. name)
            local info = get_file_info(full_path, name)
            if info then
                entries[#entries + 1] = info
                total_blocks = total_blocks + info.blocks
                if opts.recursive and info.is_dir and not is_dot then
                    subdirs[#subdirs + 1] = full_path
                end
            end
        end
    end
    C.closedir(dir)

    sort_entries(entries)
    print_entries(entries, total_blocks)

    if opts.recursive and #subdirs > 0 then
        sort_entries(subdirs)
        for _, sd in ipairs(subdirs) do
            io.write("\n")
            list_dir(sd, true)
        end
    end
end

local function main()
    local files = {}
    local dirs = {}

    for _, target in ipairs(targets) do
        local info = get_file_info(target, target)
        if not info then
            io.stderr:write("ls: cannot access '" .. target .. "': No such file or directory\n")
        else
            if info.is_dir and not opts.directory then
                dirs[#dirs + 1] = target
            else
                files[#files + 1] = info
            end
        end
    end

    if #files > 0 then
        sort_entries(files)
        print_entries(files, nil)
    end

    local show_header = (#targets > 1) or (#files > 0 and #dirs > 0)
    for i, dir in ipairs(dirs) do
        if #files > 0 or i > 1 then io.write("\n") end
        list_dir(dir, show_header)
    end
end

main()
