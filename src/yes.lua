local VERSION = "luajit-coreutils yes 0.1"

local function help()
	io.write([[
Usage: yes [STRING]...
  or:  yes OPTION
Repeatedly output a line with all specified STRINGs, or 'y'.

      --help        display this help and exit
      --version     output version information and exit
]])
end

local function version()
	print(VERSION)
end

for i = 1, #arg do
	if arg[i] == "--help" then
		help()
		os.exit(0)
	elseif arg[i] == "--version" then
		version()
		os.exit(0)
	end
end

local output

if #arg == 0 then
	output = "y"
else
	output = table.concat(arg, " ")
end

output = output .. "\n"

while true do
	local ok = io.write(output)

	if not ok then
		os.exit(1)
	end
end
