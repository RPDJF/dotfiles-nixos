#!/usr/bin/env python3

# from https://github.com/waliori/waybar_peek

"""
Waybar Peek - Auto-hide for Hyprland (Multi-monitor)
Shows waybar when cursor is at top edge, hides when workspace has windows.

Toggle auto-hide: pkill -HUP -f waybar_peek
"""

import json
import os
import signal
import socket
import time
from pathlib import Path

# Configuration
PIXEL_THRESHOLD = 5          # Show bar when within 5px of top
PIXEL_THRESHOLD_HIDE = 50    # Hide when cursor goes below 50px
POLL_INTERVAL = 0.1          # Poll every 100ms

class WaybarPeek:
    def __init__(self):
        self.xdg_runtime = os.environ.get("XDG_RUNTIME_DIR", f"/run/user/{os.getuid()}")
        self.hypr_sig = os.environ.get("HYPRLAND_INSTANCE_SIGNATURE", "")
        self.socket_path = f"{self.xdg_runtime}/hypr/{self.hypr_sig}/.socket.sock"

        self.cursor_at_top = False
        self.last_visibility = None
        self.waybar_pid = None
        self.enabled = True  # Auto-hide enabled by default

        # Setup signal handler for toggle
        signal.signal(signal.SIGHUP, self.toggle_handler)

    def toggle_handler(self, signum, frame):
        """Handle SIGHUP to toggle auto-hide on/off"""
        self.enabled = not self.enabled
        status = "enabled" if self.enabled else "disabled"
        print(f"Auto-hide {status}")

        if not self.enabled:
            # When disabled, always show the bar
            self.set_waybar_visible(True)
            self.last_visibility = True
        else:
            # When re-enabled, force state recalculation
            self.last_visibility = None

    def hypr_query(self, cmd: str) -> str:
        """Query Hyprland via socket"""
        try:
            sock = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
            sock.connect(self.socket_path)
            sock.send(cmd.encode())
            response = b""
            while True:
                chunk = sock.recv(4096)
                if not chunk:
                    break
                response += chunk
            sock.close()
            return response.decode()
        except Exception:
            return ""

    def get_cursor_pos(self) -> tuple:
        """Get cursor position as (x, y)"""
        try:
            data = json.loads(self.hypr_query("j/cursorpos"))
            return (data.get("x", 0), data.get("y", 0))
        except Exception:
            return (0, 0)

    def get_monitors(self) -> list:
        """Get all monitors with their bounds"""
        try:
            return json.loads(self.hypr_query("j/monitors"))
        except Exception:
            return []

    def check_windows(self) -> bool:
        """Check if active workspace has windows"""
        try:
            data = json.loads(self.hypr_query("j/activeworkspace"))
            return data.get("windows", 0) > 0
        except Exception:
            return False

    def find_waybar_pid(self) -> int:
        """Find waybar process ID"""
        try:
            for entry in Path("/proc").iterdir():
                if not entry.is_dir() or not entry.name.isdigit():
                    continue
                comm_file = entry / "comm"
                if comm_file.exists():
                    comm = comm_file.read_text().strip()
                    if comm in ("waybar", ".waybar-wrapped"):
                        return int(entry.name)
        except Exception:
            pass
        return None

    def set_waybar_visible(self, visible: bool) -> bool:
        """Send signal to waybar to show/hide"""
        if self.waybar_pid is None:
            self.waybar_pid = self.find_waybar_pid()

        if self.waybar_pid is None:
            return False

        try:
            sig = signal.SIGUSR2 if visible else signal.SIGUSR1
            os.kill(self.waybar_pid, sig)
            return True
        except ProcessLookupError:
            self.waybar_pid = self.find_waybar_pid()
            if self.waybar_pid:
                try:
                    sig = signal.SIGUSR2 if visible else signal.SIGUSR1
                    os.kill(self.waybar_pid, sig)
                    return True
                except Exception:
                    pass
        except Exception:
            pass
        return False

    def is_cursor_at_top(self) -> bool:
        """Check if cursor is at top edge of any monitor"""
        cursor_x, cursor_y = self.get_cursor_pos()
        monitors = self.get_monitors()

        for m in monitors:
            mx, my = m.get("x", 0), m.get("y", 0)
            mw, mh = m.get("width", 0), m.get("height", 0)

            # Check if cursor is on this monitor
            if mx <= cursor_x <= mx + mw and my <= cursor_y <= my + mh:
                # Calculate local Y position relative to this monitor
                local_y = cursor_y - my

                # Use different thresholds based on current state
                threshold = PIXEL_THRESHOLD_HIDE if self.cursor_at_top else PIXEL_THRESHOLD
                return local_y <= threshold

        return False

    def run(self):
        """Main loop"""
        print(f"waybar-peek started (PID: {os.getpid()})")
        print(f"Socket: {self.socket_path}")
        print(f"Toggle auto-hide: pkill -HUP -f waybar_peek")

        # Initial state
        windows_opened = self.check_windows()
        self.last_visibility = not windows_opened

        while True:
            try:
                # Skip auto-hide logic if disabled
                if not self.enabled:
                    time.sleep(POLL_INTERVAL)
                    continue

                # Check cursor position
                new_cursor_at_top = self.is_cursor_at_top()
                if new_cursor_at_top != self.cursor_at_top:
                    self.cursor_at_top = new_cursor_at_top

                # Check windows
                windows_opened = self.check_windows()

                # Determine visibility: show if cursor at top OR no windows
                should_be_visible = self.cursor_at_top or not windows_opened

                # Update waybar if state changed
                if should_be_visible != self.last_visibility:
                    self.set_waybar_visible(should_be_visible)
                    self.last_visibility = should_be_visible

                time.sleep(POLL_INTERVAL)

            except KeyboardInterrupt:
                print("\nExiting...")
                break
            except Exception as e:
                print(f"Error: {e}")
                time.sleep(1)

if __name__ == "__main__":
    app = WaybarPeek()
    app.run()