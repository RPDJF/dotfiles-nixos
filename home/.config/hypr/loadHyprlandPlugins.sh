#!/usr/bin/env bash

# Use HYPRPLUGIN_DIR if set, otherwise fallback
PLUGIN_DIR="${HYPRPLUGIN_DIR:-/run/current-system/sw/lib}"

# Check if directory exists
if [[ ! -d "$PLUGIN_DIR" ]]; then
  echo "Plugin directory not found: $PLUGIN_DIR"
  exit 1
fi

echo "Loading plugins from: $PLUGIN_DIR"
echo

for pluginPath in "$PLUGIN_DIR"/libhypr*; do
  # Skip if not a regular file
  [[ -f "$pluginPath" ]] || continue

  pluginName="$(basename "$pluginPath")"

  echo "Loading $pluginName..."
  hyprctl plugin load "$PLUGIN_DIR/$pluginName"
done
