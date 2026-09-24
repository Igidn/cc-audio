# cc-audio

Temporary hosting for a CC:Tweaked (ComputerCraft) speaker audio file:
**Lahai-Roi JAZZ** — [source video](https://www.youtube.com/watch?v=0Y41XMkfROU) (49:20).

## Files

| File | Link | Size |
|---|---|---|
| Full track | [`v1/lahai-roi-jazz.dfpwm`](https://github.com/Igidn/cc-audio/releases/download/v1/lahai-roi-jazz.dfpwm) | 17,764,868 B (~16.9 MiB) |
| Split parts | `v2/part01.dfpwm` … `v2/part34.dfpwm` | 524,288 B each (last 463,364 B) |
| [`play_parts.lua`](play_parts.lua) | streams the parts in order + loops forever | |
| [`combine.lua`](combine.lua) | joins the parts back into one file | |
| [`play.lua`](play.lua) | plays one local DFPWM file | |

- Format: **DFPWM1a** (`cc.audio.dfpwm`), 48 kHz mono, 1 bit/sample (6,000 B/s), raw stream, no header.
- SHA-256 of the full file: `8d800eb0b346c5b2eedbf1b5f606be6667cd065130989aca1e4330da286c4625`
- The parts are simply the full file cut every 524,288 bytes; concatenated, they are byte-identical to it.

## CC:Tweaked limits (upstream defaults)

| Limit | Default | Config option |
|---|---|---|
| HTTP response, per request | **16 MiB** (16,777,216 B) | `http.rules` → `max_download` |
| HTTP request body | 4 MiB | `http.rules` → `max_upload` |
| Websocket message | 128 KiB | `http.rules` → `max_websocket_message` |
| Concurrent HTTP requests | 16 | `http.max_requests`, `http.max_websockets` (4) |
| Computer disk space | 1,000,000 B | `computer_space_limit` |
| Floppy disk space | 125,000 B | `floppy_space_limit` |
| HTTP bandwidth (all computers together) | 32 MiB/s each way | `http.bandwidth.global_download` / `global_upload` |

The full file is **~1 MB over the 16 MiB per-request download cap**, so a plain `http.get`/wget of it aborts with `Response is too large` before the disk size even matters. Servers can raise it:

```toml
[[http.rules]]
host = "github.com"
max_download = 33554432 # 32 MiB
```

But a stock computer still can't store a 17 MB file (1 MB disk) — hence the parts + streaming player.

## In game

Stream all parts and loop forever (only one 512 KiB part is in memory/downloaded at a time):

```text
wget https://raw.githubusercontent.com/Igidn/cc-audio/main/play_parts.lua
play_parts
```

- Downloads `part01.dfpwm` … `part34.dfpwm` from release `v2` and feeds them to the speaker through `cc.audio.dfpwm` as one continuous stream.
- If ~17.8 MB of disk is free, parts are cached next to the script, so later loops are offline. Otherwise it re-streams each loop. Ctrl+T stops it.

Alternatively, join them into a single file (needs ~17.8 MB free):

```text
wget https://raw.githubusercontent.com/Igidn/cc-audio/main/combine.lua
combine
play lahai-roi-jazz.dfpwm
```

## How it was made

Encoded with FFmpeg 9's native `dfpwm` encoder:

```sh
ffmpeg -i source.webm -vn -ac 1 -ar 48000 -c:a dfpwm -f dfpwm lahai-roi-jazz.dfpwm
```

The first 120 seconds were verified **byte-identical** to CC:Tweaked's own `cc.audio.dfpwm` Lua encoder (run locally; its official test vectors were used too), and a full decode round-trip was checked.
