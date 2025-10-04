# HTTP Server in Pure ARM64 Assembly (macOS Apple Silicon) — Now With Random Emoji 🎲✨

*Because sometimes the best way to learn is to do the most ridiculous thing that still works.*

This repo contains a tiny HTTP server written in **pure ARM64 assembly** for **macOS (Apple Silicon)**.  
It listens on **port 8585** and serves a **random emoji** in a minimal HTML page on each refresh.

> Inspired by: [“I wrote an HTTP server in assembly (and it actually works)”](https://suddo.io/backend/234156-i-wrote-an-http-server-in-assembly-and-it-actually-works) — with extra chaos (and emojis) added.

---

## 🚀 What You Get

- ✅ **Pure assembly** (no C, no frameworks)  
- 🌐 **HTTP/1.1** with **chunked encoding** (so we can swap body size freely)  
- 🎰 **Random emoji per request** using `arc4random_uniform`  
- 🍏 Built for **macOS ARM64 (M1/M2/M3)**  
- 🔌 Listens on **`0.0.0.0:8585`**

---

## 🧱 Files

- `http_server_arm64_emoji.s` — the entire server in one assembly file

---

## 🛠️ Requirements

- macOS on Apple Silicon (M1/M2/M3)
- Xcode Command Line Tools (for `clang`)
- A terminal and a sense of adventure 🧭

---

## 🛠️ Build & Run

```bash
# 1) Build
clang -Wall -Wextra -o http_asm_emoji http_server_arm64_emoji.s

# 2) Run
./http_asm_emoji

# 3) Test (new emoji on each refresh)
open http://localhost:8585
# or:
curl -s http://localhost:8585
```

Expected HTML (emoji varies on every request):

```html
<!doctype html><html><body><h1>🦀</h1></body></html>
```

Stop with `Ctrl+C`.

---

## 🧩 How It Works (at a glance)

```
socket(AF_INET, SOCK_STREAM, 0)
  → setsockopt(SO_REUSEADDR)
    → bind(0.0.0.0:8585)
      → listen(BACKLOG)
        └─ accept() loop:
            1) pick random index via arc4random_uniform(N)
            2) write HTTP headers (Transfer-Encoding: chunked)
            3) write chunk size line for body
            4) write HTML body with one emoji
            5) write chunk terminator; close()
```

**Why chunked encoding?**  
We avoid recalculating `Content-Length` on each request. The body stays flexible, and the server stays tiny.

---

## 🎲 Customize the Emoji Pool

Inside the `.data` section there are **10 prebuilt bodies** like:

```asm
body0: .ascii "<!doctype html><html><body><h1>ð</h1></body></html>
" // 😀
...
body9: .ascii "<!doctype html><html><body><h1>ð¦</h1></body></html>
" // 🦀
```

To add your own:

1. Append a new `bodyN:` line with your UTF-8 bytes (`ð...` style is safest).  
2. Keep **exactly the same length** as the others (55 bytes here) OR update:
   - `BODY_LEN` constant,
   - the hex chunk size string (e.g., `"37
"` for 0x37 = 55),
   - `EMOJI_COUNT`.
3. Add the new label to the `body_ptrs` table.
4. Rebuild. Done. 🎉

---

## 🧪 Smoke Test

```bash
# One-liners
curl -sv http://localhost:8585/ 2>&1 | head -n 20
for i in {1..5}; do curl -s http://localhost:8585/ | sed 's/.*<h1>\(.*\)<\/h1>.*//'; done
```

---

## 🐞 Troubleshooting

- **macOS asks to allow network connections** → Click “Allow.”  
- **Port already in use** → Change the `.hword 0x8921` (8585) to another port (remember network byte order).  
- **Weird characters instead of emoji** → Your terminal/font might not support that glyph; try another emoji.  
- **No randomness** → `arc4random_uniform` is used; if you cache results via a proxy, disable caching.

---

## ⚠️ Notes

- This is a **learning PoC**, not a production server.  
- No TLS, no parsing, minimal error handling.  
- If you ship this to prod, at least add a hat and a seatbelt. 🪖

---

## 📚 References

- ARM64 Procedure Call Standard (AArch64)  
- macOS/BSD sockets (`/usr/include/sys/socket.h`)  
- `arc4random_uniform(3)`

---

## 📜 License

MIT — go build wonderfully unnecessary things.
