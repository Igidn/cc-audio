-- Play a DFPWM file through a CC:Tweaked speaker.
-- usage: play <file.dfpwm>
local dfpwm = require("cc.audio.dfpwm")
local speaker = peripheral.find("speaker")
if not speaker then error("No speaker attached", 0) end

local path = ...
if not path then error("usage: play <file.dfpwm>", 0) end

local decoder = dfpwm.make_decoder()
for chunk in io.lines(path, 16 * 1024) do
  local buffer = decoder(chunk)
  while not speaker.playAudio(buffer) do
    os.pullEvent("speaker_audio_empty")
  end
end
