#!/usr/bin/env bash

BASE_DIR="${HOME}/.docker-composers"

# ----------------------------
# APP DISCOVERY
# ----------------------------

list_apps() {
  shopt -s nullglob

  for f in "$BASE_DIR"/*.docker-compose.yml; do
    name=$(basename "$f")
    name="${name%.docker-compose.yml}"
    [[ "$name" == "traefik" ]] && continue
    echo "$name"
  done
}

is_running() {
  local app="$1"
  docker compose -p "$app" \
    -f "$BASE_DIR/$app.docker-compose.yml" \
    ps -q 2>/dev/null | grep -q .
}

any_running() {
  for app in $(list_apps); do
    if is_running "$app"; then
      return 0
    fi
  done
  return 1
}

# ----------------------------
# TRAEFIK
# ----------------------------

traefik_up() {
  docker compose -p traefik \
    -f "$BASE_DIR/traefik.docker-compose.yml" up -d
}

traefik_down() {
  docker compose -p traefik \
    -f "$BASE_DIR/traefik.docker-compose.yml" down
}

sync_traefik() {
  if any_running; then
    echo "🚀 Apps running → ensuring Traefik is UP"
    traefik_up
  else
    echo "🛑 No apps running → stopping Traefik"
    traefik_down
  fi
}

# ----------------------------
# CONTAINER INTELLIGENCE (FIXED)
# ----------------------------

list_all_containers() {
  docker ps --format "{{.Names}}"
}

is_managed_container() {
  local container="$1"

  for app in $(list_apps); do
    if docker inspect "$container" 2>/dev/null \
      | grep -q "\"com.docker.compose.project\": \"$app\""; then
      return 0
    fi
  done

  return 1
}

# ----------------------------
# STATUS (FIXED - SHOW EVERYTHING)
# ----------------------------

cmd_status() {
  echo "📊 MANAGED APPS:"
  echo

  for app in $(list_apps); do
    if is_running "$app"; then
      echo "🟢 $app (running)"
    else
      echo "🔴 $app (stopped)"
    fi
  done

  echo
  echo "🧩 RUNNING CONTAINERS:"
  echo

  if [ -z "$(docker ps -q)" ]; then
    echo "  (none)"
  else
    while read -r c; do
      if is_managed_container "$c"; then
        echo "🟢 $c (managed)"
      else
        echo "⚠️ $c (external)"
      fi
    done < <(docker ps --format "{{.Names}}")
  fi

  echo
  echo "🌐 Traefik:"
  any_running && echo "🟢 SHOULD RUN" || echo "🔴 SHOULD STOP"
}

# ----------------------------
# START / STOP
# ----------------------------

cmd_start() {
  local app="$1"
  [ -z "$app" ] && echo "Usage: start <app>" && exit 1

  echo "🚀 Starting Traefik..."
  traefik_up

  echo "🚀 Starting $app..."

  docker compose -p "$app" \
    -f "$BASE_DIR/$app.docker-compose.yml" \
    down --remove-orphans >/dev/null 2>&1

  docker compose -p "$app" \
    -f "$BASE_DIR/$app.docker-compose.yml" \
    up -d
}


cmd_stop() {
  local app="$1"

  echo "🛑 Stopping $app..."

  docker compose -p "$app" \
    -f "$BASE_DIR/$app.docker-compose.yml" \
    down --remove-orphans

  sync_traefik
}

cmd_logs() {
  local app="$1"
  [ -z "$app" ] && echo "Usage: logs <app>" && exit 1

  docker compose -p "$app" \
    -f "$BASE_DIR/$app.docker-compose.yml" \
    logs -f
}

cmd_up_all() {
  for app in $(list_apps); do
    echo "🚀 Starting $app"
    docker compose -p "$app" \
      -f "$BASE_DIR/$app.docker-compose.yml" \
      up -d
  done
  sync_traefik
}

cmd_down_all() {
  for app in $(list_apps); do
    echo "🛑 Stopping $app"
    docker compose -p "$app" \
      -f "$BASE_DIR/$app.docker-compose.yml" \
      down
  done
  sync_traefik
}

# ----------------------------
# STOP ALL (FIXED UI)
# ----------------------------

cmd_stop_all() {
  echo "📊 FULL CONTAINER LIST:"
  echo

  docker ps --format "  - {{.Names}}"

  echo
  read -p "Stop ALL containers? (y/N): " confirm
  [[ "$confirm" != "y" ]] && exit 0

  echo "🛑 Stopping everything..."
  docker stop $(docker ps -q)

  echo "🧹 Cleaning networks..."
  docker network prune -f >/dev/null 2>&1

  sync_traefik
}

# ----------------------------
# INTERACTIVE UI (FIXED)
# ----------------------------

cmd_interactive() {
  echo "📦 AVAILABLE APPS:"
  echo

  apps=($(list_apps))

  for i in "${!apps[@]}"; do
    app="${apps[$i]}"

    if is_running "$app"; then
      echo "[$i] 🟢 $app (running)"
    else
      echo "[$i] 🔴 $app (stopped)"
    fi
  done

  echo
  echo "Options:"
  echo "  a = stop ALL containers"
  echo
  read -p "Select index / option (or q): " choice

  [[ "$choice" == "q" ]] && exit 0

  if [[ "$choice" == "a" ]]; then
    cmd_stop_all
    exit 0
  fi

  app="${apps[$choice]}"

  if [[ -z "$app" ]]; then
    echo "❌ Invalid selection"
    exit 1
  fi

  if is_running "$app"; then
    cmd_stop "$app"
  else
    cmd_start "$app"
  fi
}

# ----------------------------
# CLI
# ----------------------------

case "$1" in
  start) cmd_start "$2" ;;
  stop) cmd_stop "$2" ;;
  status) cmd_status ;;
  logs) cmd_logs "$2" ;;
  up) cmd_up_all ;;
  down) cmd_down_all ;;
  stop-all) cmd_stop_all ;;
  interactive|"") cmd_interactive ;;
  *)
    echo "Commands:"
    echo "  start <app>"
    echo "  stop <app>"
    echo "  status"
    echo "  logs <app>"
    echo "  up"
    echo "  down"
    echo "  stop-all"
    echo "  interactive"
    ;;
esac
