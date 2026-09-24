-- Play "something" (CC:Tweaked DFPWM) by streaming it in parts, looping forever.
--
-- The track is split into 512 KiB parts of one continuous DFPWM stream
-- (part01.dfpwm .. part14.dfpwm). Each part is downloaded, played, and - if
-- there is enough disk space - cached, so later loops do not re-download.
--
-- Everything is hardcoded below; no arguments needed. Ctrl+T stops it.

local dfpwm = require("cc.audio.dfpwm")
local speaker = peripheral.find("speaker")
if not speaker then error("No speaker attached", 0) end

-- =========================== hardcoded config ===========================
local BASE = "https://github.com/Igidn/cc-audio/releases/download/something/"
local PARTS = 14
local TOTAL_BYTES = 7126901 -- only used to decide whether caching is worth it
local CHUNK = 16 * 1024      -- DFPWM bytes per playAudio call (= 128 Ki samples)
local CACHE = true           -- cache parts on disk between loops
-- =========================================================================

local function part_name(i)
  return string.format("part%02d.dfpwm", i)
end

local dir = fs.getDir(shell.getRunningProgram())
local function part_path(i)
  return fs.combine(dir, part_name(i))
end

local cache = false
if CACHE then
  local free = fs.getFreeSpace(dir)
  cache = free ~= nil and free >= TOTAL_BYTES + 65536
  if not cache then print("Not enough space to cache everything - streaming only") end
end

local decoder
local function play(read_chunk)
  while true do
    local data = read_chunk()
    if not data or #data == 0 then break end
    local buffer = decoder(data)
    while not speaker.playAudio(buffer) do
      os.pullEvent("speaker_audio_empty")
    end
  end
end

local function fetch(url)
  for attempt = 1, 5 do
    local res, err = http.get(url, nil, true)
    if res then return res end
    print(("Download failed (%s); retrying in 5s (%d/5)"):format(tostring(err), attempt))
    sleep(5)
  end
  error("download failed: " .. url, 0)
end

local function play_part(i)
  local path = part_path(i)

  if cache and fs.exists(path) then
    local file = assert(fs.open(path, "rb"))
    play(function() return file.read(CHUNK) end)
    file.close()
    return
  end

  local res = fetch(BASE .. part_name(i))
  local file = nil
  if cache then
    local ok, handle = pcall(fs.open, path, "wb")
    if ok and handle then
      file = handle
    else
      cache = false
      print("Couldn't create " .. path .. " - continuing without cache")
    end
  end

  if file then
    local write_failed = false
    play(function()
      local data = res.read(CHUNK)
      if data and not write_failed then
        if not pcall(file.write, data) then
          write_failed = true
          cache = false
          print("Ran out of space while caching - continuing without cache")
        end
      end
      return data
    end)
    file.close()
    if write_failed then fs.delete(path) end
  else
    play(function() return res.read(CHUNK) end)
  end
  res.close()
end

print(("Streaming %d parts, looping forever%s. Stop with Ctrl+T."):format(
  PARTS, cache and " (cached on disk)" or ""))

while true do
  for i = 1, PARTS do
    if i == 1 then decoder = dfpwm.make_decoder() end -- clean start each loop
    play_part(i)
  end
end
