// http_server_arm64_emoji.s
// Minimal HTTP server on macOS ARM64 (Apple Silicon)
// Random emoji on each request, served in a tiny HTML page.
// Build: clang -Wall -Wextra -o http_asm_emoji http_server_arm64_emoji.s
// Run:   ./http_asm_emoji   (then visit http://localhost:8585/ or curl it)

        .text
        .globl  _main

        .extern _socket
        .extern _setsockopt
        .extern _bind
        .extern _listen
        .extern _accept
        .extern _write
        .extern _close
        .extern _arc4random_uniform

// ------------------------------------------------------------
// Constants
// ------------------------------------------------------------
        .equ    AF_INET,           2
        .equ    SOCK_STREAM,       1
        .equ    SOL_SOCKET,        0xffff
        .equ    SO_REUSEADDR,      0x0004

        .equ    ADDR_LEN,          16
        .equ    BACKLOG,           16

        // Response parts (precomputed lengths)
        .equ    HDR_LEN,           106           // length of "headers" below
        .equ    CHUNK_SIZE_LEN,    4             // "37\r\n"
        .equ    BODY_LEN,          55            // <!doctype ...><h1>🦀</h1>...</html>\n
        .equ    CHUNK_END_LEN,     7             // "\r\n0\r\n\r\n"

        .equ    EMOJI_COUNT,       10            // number of emoji variants

// ------------------------------------------------------------
// main()
// ------------------------------------------------------------
_main:
        // socket(AF_INET, SOCK_STREAM, 0)
        mov     x0, #AF_INET
        mov     x1, #SOCK_STREAM
        mov     x2, #0
        bl      _socket
        mov     x19, x0                           // server_fd

        // setsockopt(server_fd, SOL_SOCKET, SO_REUSEADDR, &one, 4)
        mov     x0, x19
        movz    x1, #SOL_SOCKET
        mov     x2, #SO_REUSEADDR
        adrp    x3, one@PAGE
        add     x3, x3, one@PAGEOFF
        mov     x4, #4
        bl      _setsockopt

        // bind(server_fd, &addr, sizeof(addr))
        mov     x0, x19
        adrp    x1, addr@PAGE
        add     x1, x1, addr@PAGEOFF
        mov     x2, #ADDR_LEN
        bl      _bind

        // listen(server_fd, BACKLOG)
        mov     x0, x19
        mov     x1, #BACKLOG
        bl      _listen

// ------------------------------------------------------------
// Accept loop: accept -> write headers -> write chunk size -> write body -> write trailer -> close
// ------------------------------------------------------------
accept_loop:
        // accept(server_fd, NULL, NULL)
        mov     x0, x19
        mov     x1, #0
        mov     x2, #0
        bl      _accept
        mov     x20, x0                            // client_fd

        // Pick random index: arc4random_uniform(EMOJI_COUNT)
        mov     x0, #EMOJI_COUNT
        bl      _arc4random_uniform               // w0 = 0..EMOJI_COUNT-1
        uxtw    x9, w0

        // Load pointer to the chosen body
        adrp    x1, body_ptrs@PAGE
        add     x1, x1, body_ptrs@PAGEOFF
        ldr     x10, [x1, x9, lsl #3]             // x10 = selected body pointer

        // ---- write headers ----
        mov     x0, x20
        adrp    x1, headers@PAGE
        add     x1, x1, headers@PAGEOFF
        mov     x2, #HDR_LEN
        bl      _write

        // ---- write chunk size "37\r\n" (55 bytes body in hex) ----
        mov     x0, x20
        adrp    x1, chunk_size@PAGE
        add     x1, x1, chunk_size@PAGEOFF
        mov     x2, #CHUNK_SIZE_LEN
        bl      _write

        // ---- write body (selected emoji HTML) ----
        mov     x0, x20
        mov     x1, x10
        mov     x2, #BODY_LEN
        bl      _write

        // ---- write chunk end "\r\n0\r\n\r\n" ----
        mov     x0, x20
        adrp    x1, chunk_end@PAGE
        add     x1, x1, chunk_end@PAGEOFF
        mov     x2, #CHUNK_END_LEN
        bl      _write

        // close(client_fd)
        mov     x0, x20
        bl      _close

        b       accept_loop

// ------------------------------------------------------------
// Data
// ------------------------------------------------------------
        .data
        .align  4

// sockaddr_in for 0.0.0.0:8585
addr:
        .byte   16                  // sin_len
        .byte   AF_INET             // sin_family
        .hword  0x8921              // sin_port (8585 -> 0x2189 network order; little-endian store = 0x8921)
        .word   0                   // sin_addr (INADDR_ANY)
        .quad   0                   // sin_zero[8]

// setsockopt value "1"
one:
        .word   1

// HTTP/1.1 headers with chunked transfer
headers:
        .ascii  "HTTP/1.1 200 OK\r\n"
        .ascii  "Content-Type: text/html; charset=utf-8\r\n"
        .ascii  "Transfer-Encoding: chunked\r\n"
        .ascii  "Connection: close\r\n"
        .ascii  "\r\n"

// The chunk size line for 55 bytes body: 55 decimal = 0x37 hex
chunk_size:
        .ascii  "37\r\n"

// Chunk end trailer
chunk_end:
        .ascii  "\r\n0\r\n\r\n"

// --- Body variants (all exactly 55 bytes, each with a single 4-byte emoji) ---
body0:  .ascii  "<!doctype html><html><body><h1>\xF0\x9F\x98\x80</h1></body></html>\n" // 😀
body1:  .ascii  "<!doctype html><html><body><h1>\xF0\x9F\x9A\x80</h1></body></html>\n" // 🚀
body2:  .ascii  "<!doctype html><html><body><h1>\xF0\x9F\x90\xB1</h1></body></html>\n" // 🐱
body3:  .ascii  "<!doctype html><html><body><h1>\xF0\x9F\x8D\x95</h1></body></html>\n" // 🍕
body4:  .ascii  "<!doctype html><html><body><h1>\xF0\x9F\x94\xA5</h1></body></html>\n" // 🔥
body5:  .ascii  "<!doctype html><html><body><h1>\xF0\x9F\x8C\x88</h1></body></html>\n" // 🌈
body6:  .ascii  "<!doctype html><html><body><h1>\xF0\x9F\xA7\xA0</h1></body></html>\n" // 🧠
body7:  .ascii  "<!doctype html><html><body><h1>\xF0\x9F\x90\xB3</h1></body></html>\n" // 🐳
body8:  .ascii  "<!doctype html><html><body><h1>\xF0\x9F\x8E\xAF</h1></body></html>\n" // 🎯
body9:  .ascii  "<!doctype html><html><body><h1>\xF0\x9F\xA6\x80</h1></body></html>\n" // 🦀

// Pointer table to bodies
        .align  3
body_ptrs:
        .quad body0
        .quad body1
        .quad body2
        .quad body3
        .quad body4
        .quad body5
        .quad body6
        .quad body7
        .quad body8
        .quad body9
