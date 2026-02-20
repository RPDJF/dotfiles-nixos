# oled care animations

while true; do
  for i in $(seq 0 2 359); do
    hyprctl keyword general:col.active_border "rgba(c6a0f6cc) rgba(b57a3acc) ${i}deg"
        # subtle opacity flicker
    opacity=$(echo "0.88 + 0.02 * s($i * 0.01745)" | bc -l)  # sine wave
    hyprctl keyword decoration:active_opacity $opacity
    hyprctl keyword decoration:inactive_opacity $(echo "$opacity - 0.2" | bc)
    sleep 0.03
  done
done
