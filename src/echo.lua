#!/usr/bin/env luajit

local VERSION = "luajit-coreutils echo 0.1"

local function write(s)
	io.write(s)
end

local function help()
	write([[
Usage: echo [SHORT-OPTION]... [STRING]...
  or:  echo LONG-OPTION

Echo the STRING(s) to standard output.

  -n        do not output the trailing newline
  -e        enable interpretation of backslash escapes
  -E        disable interpretation of backslash escapes (default)

      --help     display this help and exit
      --version  output version information and exit

If -e is in effect, the following sequences are recognized:

  \\        backslash
  \a        alert (BEL)
  \b        backspace
  \c        produce no further output
  \e        escape
  \f        form feed
  \n        new line
  \r        carriage return
  \t        horizontal tab
  \v        vertical tab
  \0NNN     byte with octal value NNN (1 to 3 digits)
  \xHH      byte with hexadecimal value HH (1 to 2 digits)
]])
end


local function version()
	write(VERSION .. "\n")
end


local function parse_escape(s)
	local out = {}
	local i = 1
	local stop = false

	while i <= #s do
		local c = s:sub(i,i)

		if c ~= "\\" then
			out[#out+1] = c
			i = i + 1
		else
			i = i + 1

			if i > #s then
				out[#out+1] = "\\"
				break
			end

			local e = s:sub(i,i)

			if e == "a" then
				out[#out+1] = "\7"

			elseif e == "b" then
				out[#out+1] = "\8"

			elseif e == "c" then
				stop = true
				break

			elseif e == "e" then
				out[#out+1] = "\27"

			elseif e == "f" then
				out[#out+1] = "\12"

			elseif e == "n" then
				out[#out+1] = "\10"

			elseif e == "r" then
				out[#out+1] = "\13"

			elseif e == "t" then
				out[#out+1] = "\9"

			elseif e == "v" then
				out[#out+1] = "\11"

			elseif e == "\\" then
				out[#out+1] = "\\"

			elseif e == "0" then
				local oct = s:sub(i+1,i+3)
				local digits = oct:match("^([0-7]+)")

				if digits then
					out[#out+1] = string.char(tonumber(digits,8))
					i = i + #digits
				else
					out[#out+1] = "\0"
				end

			elseif e == "x" then
				local hex = s:sub(i+1,i+2)
				local digits = hex:match("^([0-9a-fA-F]+)")

				if digits then
					out[#out+1] = string.char(tonumber(digits,16))
					i = i + #digits
				else
					out[#out+1] = "\\x"
				end

			else
				out[#out+1] = "\\" .. e
			end

			i = i + 1
		end
	end

	return table.concat(out), stop
end
local no_newline = false
local escape = false
local args = {}

local i = 1

while i <= #arg do
local a = arg[i]

if a == "--help" then
help()
os.exit(0)

elseif a == "--version" then
version()
os.exit(0)

elseif a == "--" then
for j = i + 1, #arg do
args[#args+1] = arg[j]
end
break

elseif a == "-n" and #args == 0 then
no_newline = true

elseif a == "-e" and #args == 0 then
escape = true

elseif a == "-E" and #args == 0 then
escape = false

elseif a:match("^%-[neE]+$") and #args == 0 then
for c in a:gmatch(".") do
if c == "n" then
no_newline = true
elseif c == "e" then
escape = true
elseif c == "E" then
escape = false
end
end

else
for j = i, #arg do
args[#args+1] = arg[j]
end
break
end

i = i + 1
end


local result = {}

for n = 1, #args do
local s = args[n]

if escape then
local converted, stop = parse_escape(s)
result[#result+1] = converted

if stop then
break
end
else
result[#result+1] = s
end
end


io.write(table.concat(result, " "))

if not no_newline then
io.write("\n")
end

os.exit(0)
