#!/usr/bin/env bash
#
# demo.sh - run the Open-RMF fleet demo from the official Docker images.
#
# A thin wrapper around the commands from the demo guide; each subcommand is
# one step, the docker commands are kept verbatim:
#
#   ./demo.sh run-server          # start the rmf-web API server (localhost:8000)
#   ./demo.sh run-dashboard       # start the web dashboard (localhost:3000)
#   ./demo.sh check               # verify the containers are running
#   ./demo.sh download [scene]    # pre-download the scene's Gazebo models (default: office)
#   ./demo.sh run [scene]         # launch the simulation (default: office)
#   ./demo.sh task <name> [args]  # dispatch a task in the running simulation
#   ./demo.sh shell               # open a sourced shell in the simulation container
#   ./demo.sh stop                # stop all demo containers

set -euo pipefail

IMAGE="${IMAGE:-ghcr.io/open-rmf/rmf/rmf_demos:kilted-rmf-latest}"
SCENES=(office airport_terminal hotel clinic campus)
# dispatch_* entry points shipped in rmf_demos_tasks
TASKS=(patrol delivery cart_delivery clean go_to_place teleop action loop dynamic_event json)

log() { printf '\033[1;34m==>\033[0m %s\n' "$*"; }
die() { printf '\033[1;31merror:\033[0m %s\n' "$*" >&2; exit 1; }

usage() {
  cat <<EOF
Usage: $(basename "$0") <command> [args]

Commands:
  run-server         Start the rmf-web API server on localhost:8000
  run-dashboard      Start the web dashboard on localhost:3000
  check              Verify the rmf_api_server and rmf_dashboard containers are running
  download [scene]   Pre-download the scene's Gazebo models into a Docker volume
                     (default: office)
  run [scene]        Launch the simulation with GPU rendering (default: office)
  task <name> [args] Dispatch a task inside the running simulation, e.g.:
                       task patrol -p pantry lounge coe -n 3
                     (name maps to 'ros2 run rmf_demos_tasks dispatch_<name>';
                     --use_sim_time is appended if missing)
  shell              Open a sourced bash shell in the simulation container
  stop               Stop the demo containers
  help               Show this help

Every command also accepts -h/--help, e.g.: $(basename "$0") run --help

Scenes: ${SCENES[*]}

The simulation image can be overridden with the IMAGE environment variable
(current: $IMAGE).
EOF
}

# wants_help "$@" - true when the first argument asks for help
wants_help() {
  case "${1:-}" in -h|--help|help) return 0 ;; *) return 1 ;; esac
}

help_run_server() {
  cat <<EOF
Usage: $(basename "$0") run-server

Starts the rmf-web API server (ghcr.io/open-rmf/rmf-web/api-server:kilted-nightly)
as a detached container named 'rmf_api_server' on the host network. The fleet
adapters stream robot and task state into it; it serves the REST/WebSocket API
on localhost:8000 (Swagger UI at localhost:8000/docs). Takes no arguments.
EOF
}

help_run_dashboard() {
  cat <<EOF
Usage: $(basename "$0") run-dashboard

Starts the rmf-web dashboard (ghcr.io/open-rmf/rmf-web/demo-dashboard:latest)
as a detached container named 'rmf_dashboard' serving the web UI on
localhost:3000. Start the API server first ($(basename "$0") run-server).
Takes no arguments.
EOF
}

help_check() {
  cat <<EOF
Usage: $(basename "$0") check

Runs 'docker ps' and reports whether the rmf_api_server and rmf_dashboard
containers are running. Exits non-zero if either is missing. Takes no arguments.
EOF
}

help_download() {
  cat <<EOF
Usage: $(basename "$0") download [scene]

Pre-downloads the scene's Gazebo (Fuel) models into the Docker volume
'rmf_gz_models_<scene>' so the simulation starts fast. Already-cached models
are skipped, so re-running is cheap. Done once per scene.

Available scenes (default: office):
$(printf '  %s\n' "${SCENES[@]}")
EOF
}

help_run() {
  cat <<EOF
Usage: $(basename "$0") run [scene]

Launches the scene's simulation (Gazebo + RViz windows) in the foreground with
GPU rendering, connected to the API server at ws://localhost:8000/_internal.
Ctrl-C stops it. Run '$(basename "$0") run-server', 'run-dashboard' and
'download <scene>' first.

Available scenes (default: office):
$(printf '  %s\n' "${SCENES[@]}")
EOF
}

help_task() {
  cat <<EOF
Usage: $(basename "$0") task <name> [args...]

Dispatches a task inside the running 'rmf_demos' simulation container via
'ros2 run rmf_demos_tasks dispatch_<name>'. Arguments are passed through
unchanged and --use_sim_time is appended if missing.

Available tasks:
$(printf '  %s\n' "${TASKS[@]}")

Each task has its own arguments; ask the task itself (requires the simulation
to be running):
  $(basename "$0") task patrol --help

Example:
  $(basename "$0") task patrol -p pantry lounge coe -n 3
EOF
}

help_shell() {
  cat <<EOF
Usage: $(basename "$0") shell

Opens an interactive bash shell inside the running 'rmf_demos' simulation
container with the ROS 2 and rmf_demos workspaces sourced, ready for ad-hoc
'ros2' commands (topic echo, node list, manual task dispatch, ...).
Requires the simulation to be running ($(basename "$0") run). Takes no arguments.
EOF
}

help_stop() {
  cat <<EOF
Usage: $(basename "$0") stop

Stops the rmf_demos, rmf_dashboard and rmf_api_server containers (all started
with --rm, so they are removed on stop). Takes no arguments.
EOF
}

validate_scene() {
  local s
  for s in "${SCENES[@]}"; do
    [ "$s" = "$1" ] && return 0
  done
  die "unknown scene '$1' (available: ${SCENES[*]})"
}

cmd_run_server() {
  wants_help "$@" && { help_run_server; return 0; }
  log "Starting the API server on localhost:8000"
  docker run -d --network host -it --rm \
    --name rmf_api_server \
    -e ROS_DOMAIN_ID=0 \
    -e RMW_IMPLEMENTATION=rmw_fastrtps_cpp \
    ghcr.io/open-rmf/rmf-web/api-server:kilted-nightly
}

cmd_run_dashboard() {
  wants_help "$@" && { help_run_dashboard; return 0; }
  log "Starting the dashboard on localhost:3000"
  docker run -d --network host -it --rm \
    --name rmf_dashboard \
    ghcr.io/open-rmf/rmf-web/demo-dashboard:latest
}

cmd_check() {
  wants_help "$@" && { help_check; return 0; }
  docker ps
  echo
  local c ok=1
  for c in rmf_api_server rmf_dashboard; do
    if [ -n "$(docker ps -q -f "name=^${c}$")" ]; then
      log "$c is running"
    else
      printf '\033[1;31mmissing:\033[0m %s is NOT running\n' "$c"
      ok=0
    fi
  done
  [ "$ok" = 1 ]
}

cmd_download() {
  wants_help "$@" && { help_download; return 0; }
  SCENE="${1:-office}" # or airport_terminal, hotel, clinic or campus
  validate_scene "$SCENE"

  VOLUME=rmf_gz_models_$SCENE

  log "Pre-downloading Gazebo models for '$SCENE' into volume '$VOLUME'"
  docker run --rm -v $VOLUME:/root/.gz \
      -e WORLD="/rmf_demos_ws/install/rmf_demos_maps/share/rmf_demos_maps/maps/${SCENE}/${SCENE}.world" \
      $IMAGE bash -c '
        grep -ohE "https://fuel\.gazebosim\.org/[^<]+" "${WORLD}" | sort -u |
        while read -r uri; do
          cached="/root/.gz/fuel/$(echo "${uri#https://}" | sed "s|/1.0/|/|" | tr "[:upper:]" "[:lower:]")"
          if [ -d "${cached}" ] && [ -n "$(ls -A "${cached}")" ]; then
            echo "cached: ${uri}"
          else
            echo "==> downloading ${uri}"
            gz fuel download -u "${uri}"
          fi
        done
      '
  docker volume ls # should show rmf_gz_models_<scene>
}

cmd_run() {
  wants_help "$@" && { help_run; return 0; }
  SCENE="${1:-office}"
  validate_scene "$SCENE"

  if command -v xhost >/dev/null 2>&1 && [ -n "${DISPLAY:-}" ]; then
    log "Allowing local containers to use the X server (xhost +local:docker)"
    xhost +local:docker
  fi

  log "Launching scene '$SCENE' (Ctrl-C to stop) - dashboard: http://localhost:3000"
  docker run -it --rm \
      --network host \
      --name rmf_demos \
      --device /dev/kfd \
      --device /dev/dri \
      --group-add video \
      --group-add $(getent group render | cut -d: -f3) \
      -e DISPLAY=$DISPLAY \
      -e QT_X11_NO_MITSHM=1 \
      -e ROS_DOMAIN_ID=0 \
      -e RMW_IMPLEMENTATION=rmw_fastrtps_cpp \
      -v /tmp/.X11-unix:/tmp/.X11-unix:ro \
      -v rmf_gz_models_$SCENE:/root/.gz \
      $IMAGE \
      bash -c "ros2 launch rmf_demos_gz ${SCENE}.launch.xml headless:=0 server_uri:=\"ws://localhost:8000/_internal\""
}

cmd_task() {
  wants_help "$@" && { help_task; return 0; }
  [ $# -ge 1 ] || die "usage: $(basename "$0") task <name> [args...], e.g. task patrol -p pantry lounge coe -n 3"
  [ -n "$(docker ps -q -f 'name=^rmf_demos$')" ] || die "the 'rmf_demos' simulation container is not running (start it with: $(basename "$0") run)"

  local name=$1; shift
  case "$name" in dispatch_*) ;; *) name="dispatch_${name}" ;; esac

  local args=("$@") a has_sim_time=0
  for a in "$@"; do [ "$a" = "--use_sim_time" ] && has_sim_time=1; done
  [ "$has_sim_time" = 1 ] || args+=(--use_sim_time)

  log "Dispatching: ros2 run rmf_demos_tasks $name ${args[*]}"
  docker exec -it rmf_demos bash -c \
    "source /opt/ros/kilted/setup.bash && source /rmf_demos_ws/install/setup.bash &&
     ros2 run rmf_demos_tasks $name ${args[*]}"
}

cmd_shell() {
  wants_help "$@" && { help_shell; return 0; }
  [ -n "$(docker ps -q -f 'name=^rmf_demos$')" ] || die "the 'rmf_demos' simulation container is not running (start it with: $(basename "$0") run)"

  docker exec -it rmf_demos bash -c \
    'source /opt/ros/kilted/setup.bash && source /rmf_demos_ws/install/setup.bash && exec bash'
}

cmd_stop() {
  wants_help "$@" && { help_stop; return 0; }
  local c stopped=0
  for c in rmf_demos rmf_dashboard rmf_api_server; do
    if [ -n "$(docker ps -q -f "name=^${c}$")" ]; then
      log "Stopping $c"
      docker stop "$c" >/dev/null
      stopped=1
    fi
  done
  [ "$stopped" = 1 ] || log "No demo containers running."
}

[ $# -ge 1 ] || { usage; exit 1; }
command=$1; shift

case "$command" in
  run-server)    cmd_run_server "$@" ;;
  run-dashboard) cmd_run_dashboard "$@" ;;
  check)         cmd_check "$@" ;;
  download)      cmd_download "$@" ;;
  run)           cmd_run "$@" ;;
  task)          cmd_task "$@" ;;
  shell)         cmd_shell "$@" ;;
  stop)          cmd_stop "$@" ;;
  help|-h|--help) usage ;;
  *) die "unknown command '$command' (see: $(basename "$0") help)" ;;
esac
