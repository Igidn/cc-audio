# cc-audio

Temporary hosting for a CC:Tweaked (ComputerCraft) speaker audio file.

## File

**[`lahai-roi-jazz.dfpwm`](https://github.com/Igidn/cc-audio/releases/download/v1/lahai-roi-jazz.dfpwm)** — 17,764,868 bytes (~16.9 MiB), 49:20

- Format: **DFPWM1a** (`cc.audio.dfpwm`), 48 kHz mono, 1 bit/sample (6,000 bytes/s), raw stream, no header
- Source: <https://www.youtube.com/watch?v=0Y41XMkfROU> (Wuthering Waves — Lahai-Roi JAZZ)
- SHA-256: `8d800eb0b346c5b2eedbf1b5f606be6667cd065130989aca1e4330da286c4625`
- Encoded with FFmpeg 9.0's native `dfpwm` encoder, which was verified **byte-identical** to CC:Tweaked's own `cc.audio.dfpwm` encoder:

  ```sh
  ffmpeg -i source.webm -vn -ac 1 -ar 48000 -c:a dfpwm -f dfpwm lahai-roi-jazz.dfpwm
  ```

## Download it (in game)

`wget` is not part of the base ROM, but most servers ship one. With plain `http`:

```lua
-- fetch <url> <path>
local url, path = ...
local res = assert(http.get(url, nil, true))
local f = assert(fs.open(path, "wb"))
while true do
    local chunk = res.read(16 * 1024)
    if not chunk then break end
    f.write(chunk)
end
f.close()
res.close()
print("saved " .. path)
```

```lua
fetch("https://github.com/Igidn/cc-audio/releases/download/v1/lahai-roi-jazz.dfpwm", "lahai-roi-jazz.dfpwm")
```

> **Heads up:** the whole response is buffered in the computer's memory, so ~17 MB must fit. Stock CC:Tweaked computers will need their limits raised (or ask for a trimmed/lower-rate cut).

## Play it

`play.lua` in this repo is the canonical player:

```lua
local dfpwm = require("cc.audio.dfpwm")
local speaker = peripheral.find("speaker")
assert(speaker, "No speaker attached")

local decoder = dfpwm.make_decoder()
for chunk in io.lines("lahai-roi-jazz.dfpwm", 16 * 1024) do
    local buffer = decoder(chunk)
    while not speaker.playAudio(buffer) do
        os.pullEvent("speaker_audio_empty")
    end
end
```

Grab it with:

```text
wget https://raw.githubusercontent.com/Igidn/cc-audio/main/play.lua play.lua
play lahai-roi-jazz.dfpwm
```

## Why this format

CC:Tweaked speakers play 48 kHz 8-bit PCM, and `cc.audio.dfpwm` is the built-in codec — 1 bit per sample keeps a 49-minute track at ~17 MB instead of ~270 MB for PCM or ~135 MB for 8-bit PCM.
