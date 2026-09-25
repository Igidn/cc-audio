-- Play the hosted playlist (CC:Tweaked DFPWM) in order, looping forever.
--
-- Each track is split into 512 KiB parts of one continuous DFPWM stream
-- (t01-part01.dfpwm, ...). Every part is downloaded, played, and cached on
-- disk if there is enough space, so later loops do not re-download.
--
-- usage: play_playlist [start_track]      (default 1; Ctrl+T stops it)

local dfpwm = require("cc.audio.dfpwm")
local speaker = peripheral.find("speaker")
if not speaker then error("No speaker attached", 0) end

-- =========================== hardcoded config ===========================
local BASE = "https://github.com/Igidn/cc-audio/releases/download/playlist/"
local CHUNK = 16 * 1024 -- DFPWM bytes per playAudio call (= 128 Ki samples)
local CACHE = true      -- cache parts on disk between loops

-- name, parts, bytes
local TRACKS = {
  { name = "t01", parts = 3, bytes = 1340416 },
  { name = "t02", parts = 2, bytes = 796909 },
  { name = "t03", parts = 2, bytes = 830834 },
  { name = "t04", parts = 2, bytes = 965347 },
  { name = "t05", parts = 2, bytes = 750795 },
  { name = "t06", parts = 3, bytes = 1183452 },
  { name = "t07", parts = 3, bytes = 1518028 },
  { name = "t08", parts = 2, bytes = 1018846 },
  { name = "t09", parts = 2, bytes = 1025812 },
  { name = "t10", parts = 2, bytes = 786042 },
  { name = "t11", parts = 2, bytes = 888303 },
  { name = "t12", parts = 3, bytes = 1084883 },
  { name = "t13", parts = 2, bytes = 649021 },
  { name = "t14", parts = 3, bytes = 1151617 },
  { name = "t15", parts = 2, bytes = 549895 },
}
-- =========================================================================

local start = math.floor(tonumber(...) or 1)
if start < 1 or start > #TRACKS then start = 1 end

local total_bytes = 0
for _, t in ipairs(TRACKS) do total_bytes = total_bytes + t.bytes end

local dir = fs.getDir(shell.getRunningProgram())
local function part_name(track, i)
  return track.name .. "-part" .. string.format("%02d", i) .. ".dfpwm"
end

local cache = false
if CACHE then
  local free = fs.getFreeSpace(dir)
  cache = free ~= nil and free >= total_bytes + 65536
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

local function play_part(track, i)
  local path = fs.combine(dir, part_name(track, i))

  if cache and fs.exists(path) then
    local file = assert(fs.open(path, "rb"))
    play(function() return file.read(CHUNK) end)
    file.close()
    return
  end

  local res = fetch(BASE .. part_name(track, i))
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

print(("Playlist: %d tracks, %.1f minutes%s. Stop with Ctrl+T."):format(
  #TRACKS, total_bytes / 6000 / 60, cache and " (cached on disk)" or ""))

while true do
  for t = start, #TRACKS do
    local track = TRACKS[t]
    for i = 1, track.parts do
      if i == 1 then decoder = dfpwm.make_decoder() end -- clean start per track
      play_part(track, i)
    end
    print(("track %d/%d done"):format(t, #TRACKS))
  end
  start = 1
end
