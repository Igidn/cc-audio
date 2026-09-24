-- Download all DFPWM parts and join them back into one file.
-- Requires ~6.8 MB of free disk space.

local BASE = "https://github.com/Igidn/cc-audio/releases/download/something/"
local PARTS = 14
local TOTAL_BYTES = 7126901
local OUT = "something.dfpwm"
local CHUNK = 16 * 1024

local dir = fs.getDir(shell.getRunningProgram())
local path = fs.combine(dir, OUT)

local free = fs.getFreeSpace(dir)
if free and free < TOTAL_BYTES + 65536 then
  error(("Not enough disk space: need ~%d KiB, have %d KiB"):format(TOTAL_BYTES // 1024, free // 1024), 0)
end

local out = assert(fs.open(path, "wb"))
for i = 1, PARTS do
  local name = string.format("part%02d.dfpwm", i)
  local res = assert(http.get(BASE .. name, nil, true), "download failed: " .. name)
  while true do
    local data = res.read(CHUNK)
    if not data then break end
    out.write(data)
  end
  res.close()
  print(("part %02d/%02d done"):format(i, PARTS))
end
out.close()

print("Joined into " .. path)
print("Play it with:  play " .. OUT)
