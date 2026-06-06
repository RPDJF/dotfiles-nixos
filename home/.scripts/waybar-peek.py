#!/usr/bin/env python3
import os, signal, socket, subprocess, json, time

SHOW_Y = 3
HIDE_Y = 40
POLL = 0.03  # slightly faster for smoother peek

RUNTIME = os.environ.get("XDG_RUNTIME_DIR", f"/run/user/{os.getuid()}")
SIG = os.environ.get("HYPRLAND_INSTANCE_SIGNATURE")
SOCK = f"{RUNTIME}/hypr/{SIG}/.socket.sock"

visible = True
enabled = True
waybar_pid = None

# ---------- Functions ----------

def hypr(cmd):
    try:
        with socket.socket(socket.AF_UNIX, socket.SOCK_STREAM) as s:
            s.settimeout(0.1)
            s.connect(SOCK)
            s.send(cmd.encode())
            return s.recv(4096).decode()
    except:
        return ""

def cursor_y():
    try:
        return json.loads(hypr("j/cursorpos"))["y"]
    except:
        return 9999

def find_waybar():
    global waybar_pid
    try:
        out = subprocess.check_output(["pgrep", "-f", ".waybar-wrapped|waybar"])
        waybar_pid = int(out.splitlines()[0])
    except:
        waybar_pid = None

def show():
    global visible
    if visible: return
    if waybar_pid:
        try: os.kill(waybar_pid, signal.SIGUSR2)
        except ProcessLookupError:
            find_waybar()
            if waybar_pid: os.kill(waybar_pid, signal.SIGUSR2)
    visible = True

def hide():
    global visible
    if not visible: return
    if waybar_pid:
        try: os.kill(waybar_pid, signal.SIGUSR1)
        except ProcessLookupError:
            find_waybar()
            if waybar_pid: os.kill(waybar_pid, signal.SIGUSR1)
    visible = False

def toggle(signum, frame):
    global enabled
    enabled = not enabled
    print("peek:", "enabled" if enabled else "disabled")
    if not enabled: show()

signal.signal(signal.SIGHUP, toggle)

# ---------- Main Loop ----------

find_waybar()
print("waybar peek running, pid:", waybar_pid)

try:
    while True:
        if enabled:
            y = cursor_y()
            if visible and y > HIDE_Y: hide()
            elif not visible and y <= SHOW_Y: show()
        time.sleep(POLL)
except KeyboardInterrupt:
    print("exit")