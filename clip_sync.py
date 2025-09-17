#!/usr/bin/env python3
#import os
import socket
import threading
import time
import sys
import platform
import base64

# Tray / GUI
try:
    import pystray
    from pystray import MenuItem, Icon
    from PIL import Image
    TRAY_AVAILABLE = True
except:
    TRAY_AVAILABLE = False


try:
    import tkinter as tk
    from tkinter import simpledialog
    TK_AVAILABLE = True
except:
    TK_AVAILABLE = False

# Clipboard fallback
try:
    import pyperclip
    CLIP_AVAILABLE = True
except:
    CLIP_AVAILABLE = False

SYSTEM = platform.system()
_internal_clipboard = ""  # fallback

def get_clipboard() -> str:
    global _internal_clipboard
    if CLIP_AVAILABLE:
        try:
            return pyperclip.paste()
        except:
            pass
    return _internal_clipboard

def set_clipboard(text: str):
    global _internal_clipboard
    if CLIP_AVAILABLE:
        try:
            pyperclip.copy(text)
        except:
            _internal_clipboard = text
    else:
        _internal_clipboard = text


HOST = "0.0.0.0"
PORT = 6060
POLL_INTERVAL = 0.5
connections_lock = threading.Lock()
connections = []

def safe_encode(s: str) -> str:
    return base64.b64encode(s.encode("utf-8")).decode("ascii")

def safe_decode(b64: str) -> str:
    return base64.b64decode(b64.encode("ascii")).decode("utf-8", errors="ignore")

def log(*args):
    print("[{}]".format(time.strftime("%H:%M:%S")), *args)


def broadcast_encoded(encoded_msg: str, source_conn=None):
    with connections_lock:
        for c in list(connections):
            if c is source_conn:
                continue
            try:
                c.sendall((encoded_msg + "\n").encode("ascii"))
            except:
                try:
                    connections.remove(c)
                except ValueError:
                    pass

def server_clipboard_watcher():
    last_clip = get_clipboard()
    log("Server clipboard watcher started")
    while True:
        cur = get_clipboard()
        if isinstance(cur, str) and cur != last_clip:
            last_clip = cur
            encoded = safe_encode(cur)
            log("Clipboard changed -> broadcasting (len=%d)" % len(cur))
            broadcast_encoded(encoded)
        time.sleep(POLL_INTERVAL)

def handle_client(conn: socket.socket, addr):
    log("Client connected:", addr)
    with connections_lock:
        connections.append(conn)
    last_clipboard = get_clipboard()
    try:
        buf = b""
        while True:
            chunk = conn.recv(4096)
            if not chunk:
                break
            buf += chunk
            while b"\n" in buf:
                line, buf = buf.split(b"\n", 1)
                try:
                    encoded = line.decode("ascii").rstrip("\r")
                    text = safe_decode(encoded)
                except:
                    continue
                cur_clip = get_clipboard()
                if text != cur_clip:
                    set_clipboard(text)
                    log(f"<- received from {addr} (len={len(text)}) -> applied to server clipboard")
                    broadcast_encoded(encoded, source_conn=conn)
    except:
        pass
    finally:
        log("Client disconnected:", addr)
        with connections_lock:
            if conn in connections:
                connections.remove(conn)
        try:
            conn.close()
        except:
            pass

def start_server():
    server = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    server.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
    server.bind((HOST, PORT))
    server.listen(5)
    log("Server listening on", f"{HOST}:{PORT}")

    threading.Thread(target=server_clipboard_watcher, daemon=True).start()

    try:
        while True:
            conn, addr = server.accept()
            threading.Thread(target=handle_client, args=(conn, addr), daemon=True).start()
    except KeyboardInterrupt:
        log("Server shutting down")
    finally:
        server.close()

# ------------------- CLIENT -------------------
def get_server_ip():
    if TK_AVAILABLE:
        root = tk.Tk()
        root.withdraw()
        ip_address = simpledialog.askstring("Input", "Enter server IP address:", initialvalue='127.0.0.1')
        root.destroy()
        return ip_address if ip_address else '127.0.0.1'
    else:
        return input("Enter server IP: ") or '127.0.0.1'

def start_client(server_ip):
    state_lock = threading.Lock()
    last_local = get_clipboard()
    last_received = last_local

    def listener(sock):
        nonlocal last_local, last_received
        buf = b""
        while True:
            chunk = sock.recv(4096)
            if not chunk:
                log("Server closed connection")
                break
            buf += chunk
            while b"\n" in buf:
                line, buf = buf.split(b"\n", 1)
                try:
                    encoded = line.decode("ascii").rstrip("\r")
                    text = safe_decode(encoded)
                except:
                    continue
                cur_clip = get_clipboard()
                if text != cur_clip:
                    set_clipboard(text)
                    with state_lock:
                        last_received = text
                        last_local = text
                    log("<- server update applied (len=%d)" % len(text))

    def watcher_and_sender(sock):
        nonlocal last_local, last_received
        while True:
            cur = get_clipboard()
            if isinstance(cur, str):
                with state_lock:
                    if cur != last_local and cur != last_received:
                        try:
                            sock.sendall((safe_encode(cur) + "\n").encode("ascii"))
                            last_local = cur
                            log("-> sent local clipboard (len=%d)" % len(cur))
                        except:
                            return
            time.sleep(POLL_INTERVAL)

    while True:
        try:
            sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
            sock.connect((server_ip, PORT))
            log("Connected to server", f"{server_ip}:{PORT}")
            threading.Thread(target=listener, args=(sock,), daemon=True).start()
            watcher_and_sender(sock)
        except KeyboardInterrupt:
            log("Client exiting")
            try: sock.close()
            except: pass
            sys.exit(0)
        except:
            log("Connection failed, retrying in 3s...")
            try: sock.close()
            except: pass
            time.sleep(3)

# ------------------- MAIN -------------------
if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: python clip_sync.py server|client")
        sys.exit(1)

    mode = sys.argv[1].lower()
    if mode == "server":
        start_server()
    elif mode == "client":
        server_ip = get_server_ip()
        start_client(server_ip)
    else:
        print("Unknown mode. Use server or client")
        sys.exit(1)
