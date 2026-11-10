"""lab-iq · Minimal IQ client: asks IQ a question the same way the browser does.

IQ has no chat REST API: the UI speaks JSON-RPC 2.0 over WebSocket at
wss://<DX_HOST>/dx/api/iq/v1/ws (methods start_session, send_message, close_session; the
specification is in the Integrator pod: /home/dx_user/server-v1/openrpc/spec.json).
The connection goes through the DX HAProxy with the user's session cookie, so IQ acts with
their permissions. Python standard library only (nothing to install).

Usage (run by 06-iq-chat-test.sh):  python3 -I iq-chat.py <host> <cookiejar> "<question>" [lang]
"""
import base64, json, os, socket, ssl, struct, sys, time

host, jar, question = sys.argv[1], sys.argv[2], sys.argv[3]
language = sys.argv[4] if len(sys.argv) > 4 else "en"

cookies = []
for line in open(jar):
    if line.startswith("#HttpOnly_"):
        line = line[len("#HttpOnly_"):]
    elif line.startswith("#") or not line.strip():
        continue
    f = line.rstrip("\n").split("\t")
    if len(f) >= 7:
        cookies.append(f"{f[5]}={f[6]}")

ctx = ssl._create_unverified_context()          # self-signed lab certificate
sock = ctx.wrap_socket(socket.create_connection((host, 443), timeout=240), server_hostname=host)
key = base64.b64encode(os.urandom(16)).decode()
req = (f"GET /dx/api/iq/v1/ws HTTP/1.1\r\nHost: {host}\r\nUpgrade: websocket\r\nConnection: Upgrade\r\n"
       f"Sec-WebSocket-Key: {key}\r\nSec-WebSocket-Version: 13\r\nOrigin: https://{host}\r\n"
       f"Cookie: {'; '.join(cookies)}\r\n\r\n")
sock.sendall(req.encode())
resp = b""
while b"\r\n\r\n" not in resp:
    resp += sock.recv(4096)
status = resp.split(b"\r\n", 1)[0].decode()
print("handshake:", status)
if " 101 " not in status:
    sys.exit(1)
buf = resp.split(b"\r\n\r\n", 1)[1]

def send(obj):
    data = json.dumps(obj).encode()
    hdr = bytearray([0x81])
    n = len(data)
    if n < 126:   hdr.append(0x80 | n)
    elif n < 65536: hdr += bytes([0x80 | 126]) + struct.pack(">H", n)
    else:         hdr += bytes([0x80 | 127]) + struct.pack(">Q", n)
    mask = os.urandom(4)
    sock.sendall(bytes(hdr) + mask + bytes(b ^ mask[i % 4] for i, b in enumerate(data)))

def recv_exact(n):
    global buf
    while len(buf) < n:
        chunk = sock.recv(65536)
        if not chunk:
            raise EOFError("connection closed")
        buf += chunk
    out, buf = buf[:n], buf[n:]
    return out

def recv():
    msg = b""
    while True:
        b0, b1 = recv_exact(2)
        op, n = b0 & 0x0F, b1 & 0x7F
        if n == 126: n = struct.unpack(">H", recv_exact(2))[0]
        elif n == 127: n = struct.unpack(">Q", recv_exact(8))[0]
        payload = recv_exact(n)
        if op == 0x9:                       # ping -> pong
            sock.sendall(bytes([0x8A, 0x80]) + os.urandom(4)); continue
        if op == 0x8: raise EOFError("close from the server")
        msg += payload
        if b0 & 0x80:
            return json.loads(msg.decode())

def call(rid, method, params):
    send({"jsonrpc": "2.0", "id": rid, "method": method, "params": params})
    while True:
        m = recv()
        if m.get("id") == rid:
            return m
        print("  (notification:", str(m)[:120], ")")

t0 = time.time()
r = call(1, "start_session", {})
print("IQ session:", r["result"]["id"], r["result"]["status"])
sid = r["result"]["id"]
send({"jsonrpc": "2.0", "id": 2, "method": "send_message",
      "params": {"id": sid, "payload": {"question": question, "language": language}}})
answer = None
while answer is None:
    m = recv()
    res = m.get("result") or {}
    meta = res.get("metadata") or {}
    if m.get("error") or res.get("businessError"):
        print("ERROR:", json.dumps(m)[:600]); break
    if res.get("answer"):
        answer = res["answer"]; break
    print(f"  [{time.time()-t0:5.1f}s] {meta.get('type') or m.get('method')}: "
          f"{meta.get('toolName') or ''} {meta.get('label') or str(res)[:100]}")
print(f"---- final IQ answer ({time.time()-t0:.1f}s) ----")
print(answer)
send({"jsonrpc": "2.0", "id": 3, "method": "close_session", "params": {"id": sid}})
