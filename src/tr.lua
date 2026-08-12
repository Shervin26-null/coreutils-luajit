local VERSION = "luajit-coreutils tr 0.1"

local delete = false
local squeeze = false
local complement = false
local truncate = false

local function help()
print([[
Usage: tr [OPTION]... STRING1 [STRING2]

Translate, squeeze, and/or delete characters.

  -c, -C, --complement
         use complement of STRING1

  -d, --delete
         delete characters

  -s, --squeeze-repeats
         squeeze repeated characters

  -t, --truncate-set1
         truncate STRING1 to STRING2

      --help
      --version
]])
end


local function expand_class(name)

    local classes = {
        alnum = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789",
        alpha = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz",
        blank = " \t",
        cntrl = string.char(unpack((function()
            local t={}
            for i=0,31 do t[#t+1]=i end
            t[#t+1]=127
            return t
        end)())),
        digit = "0123456789",
        graph = "",
        lower = "abcdefghijklmnopqrstuvwxyz",
        print = "",
        punct = [[!"#$%&'()*+,-./:;<=>?@[\]^_`{|}~]],
        space = " \t\n\r\v\f",
        upper = "ABCDEFGHIJKLMNOPQRSTUVWXYZ",
        xdigit = "0123456789abcdefABCDEF"
    }

    if classes[name] then
        if name=="graph" then
            local t={}
            for i=33,126 do
                t[#t+1]=string.char(i)
            end
            return table.concat(t)
        elseif name=="print" then
            local t={" "}
            for i=33,126 do
                t[#t+1]=string.char(i)
            end
            return table.concat(t)
        end

        return classes[name]
    end

    return ""
end


local function expand_set(s)

    local chars={}
    local i=1

    while i<=#s do

        local class=s:match("%[:(.-):%]",i)

        if class then
            local expanded=expand_class(class)

            for j=1,#expanded do
                chars[#chars+1]=expanded:sub(j,j)
            end

            i=i+#class+4

        elseif s:sub(i,i)=="[" then

            local eq=s:match("%[=(.)=%]",i)

            if eq then
                chars[#chars+1]=eq
                i=i+4

            else

            local inside=s:match("%[(.-)%]",i)

            if inside then

                local ch,rep=inside:match("^(.)%*(.*)$")

                if ch then
                    rep=tonumber(rep,8) or tonumber(rep) or 0

                    for n=1,rep do
                        chars[#chars+1]=ch
                    end
                else
                    for j=1,#inside do
                        chars[#chars+1]=inside:sub(j,j)
                    end
                end

                i=i+#inside+2

            else
                chars[#chars+1]=s:sub(i,i)
                i=i+1
            end

            end

        elseif s:sub(i,i)=="\\" then

            local n=s:sub(i+1,i+3)

            if n:match("^%d%d?%d?$") then
                chars[#chars+1]=string.char(tonumber(n,8))
                i=i+#n+1

            else
                local map={
                    n="\n",
                    t="\t",
                    r="\r",
                    b="\b",
                    f="\f",
                    v="\v",
                    a="\a",
                    ["\\"]="\\"
                }

                chars[#chars+1]=map[s:sub(i+1,i+1)]
                    or s:sub(i+1,i+1)

                i=i+2
            end

        elseif s:sub(i+1,i+1)=="-" and i+2<=#s then

            local a=s:sub(i,i):byte()
            local b=s:sub(i+2,i+2):byte()

            for c=a,b do
                chars[#chars+1]=string.char(c)
            end

            i=i+3

        else
            chars[#chars+1]=s:sub(i,i)
            i=i+1
        end
    end

    return chars
end


local args={}

for _,a in ipairs(arg) do

    if a=="--help" then
        help()
        os.exit(0)

    elseif a=="--version" then
        print(VERSION)
        os.exit(0)

    elseif a:sub(1,1)=="-" and a:sub(2,2)~="-" and #a>2 then

        for i=2,#a do
            local c=a:sub(i,i)

            if c=="d" then
                delete=true
            elseif c=="s" then
                squeeze=true
            elseif c=="c" or c=="C" then
                complement=true
            elseif c=="t" then
                truncate=true
            end
        end

    elseif a=="-d" or a=="--delete" then
        delete=true

    elseif a=="-s" or a=="--squeeze-repeats" then
        squeeze=true

    elseif a=="-c" or a=="-C" or a=="--complement" then
        complement=true

    elseif a=="-t" or a=="--truncate-set1" then
        truncate=true

    else
        args[#args+1]=a
    end
end


local set1=expand_set(args[1] or "")
local set2=expand_set(args[2] or "")

-- GNU tr: [CHAR*] fills ARRAY2 to ARRAY1 length
local raw2=args[2] or ""
local repeat_char=raw2:match("^%[(.)%*%]$")

if repeat_char then
    set2={}
    for i=1,#set1 do
        set2[#set2+1]=repeat_char
    end
end

-- GNU tr: [CHAR*REPEAT]
local rc,rn=raw2:match("^%[(.)%*(%d+)%]$")

if rc and rn then
    set2={}
    local count=tonumber(rn,8) or tonumber(rn)
    for i=1,count do
        set2[#set2+1]=rc
    end
end


if truncate then
    while #set1>#set2 do
        table.remove(set1)
    end
end


local map={}
local set1lookup={}

for _,c in ipairs(set1) do
    set1lookup[c]=true
end


if not delete then

    for i,c in ipairs(set1) do
        map[c]=set2[i] or set2[#set2]
    end

end


local input=io.read("*a")
local output={}

squeezelookup={}

if squeeze then
    local squeeze_set=set2
    if #squeeze_set==0 then
        squeeze_set=set1
    end

    for _,c in ipairs(squeeze_set) do
        squeezelookup[c]=true
    end
end

if complement then
    local all={}
    for i=0,255 do
        all[string.char(i)]=true
    end

    for _,c in ipairs(set1) do
        all[c]=nil
    end

    set1lookup={}
    for c,_ in pairs(all) do
        set1lookup[c]=true
    end
end

local last=nil

for i=1,#input do

    local c=input:sub(i,i)

    local match=set1lookup[c]

    if delete and match then

    else

        if map[c] then
            c=map[c]
        end

        if squeeze and c==last and squeezelookup[c] then

        else
            output[#output+1]=c
            last=c
        end
    end
end


io.write(table.concat(output))
