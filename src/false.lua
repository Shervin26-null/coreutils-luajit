local VERSION = "luajit-coreutils false 0.1"

local args = arg

for i = 1, #args do
	local a = args[i]

	if a == "--help" then
		io.write([[
Usage: false [OPTION]...
Do nothing, unsuccessfully.

  --help      display this help and exit
  --version   output version information and exit
]])
		os.exit(0)

	elseif a == "--version" then
		io.write(VERSION, "\n")
		os.exit(0)
	end
end

os.exit(1)
