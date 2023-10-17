#!/bin/bash

CWD=$(pwd)
APP="${CWD}/simphooks"
PROG_NAME=$0
ACTION=$1
PIDF="pid"
NOHUP=$(which nohup 2>/dev/null)
PGREP=$(which pgrep 2>/dev/null)
CURR_PID=
STD_OUTF="${CWD}/app.log"

usage() {
  printf """Usage: $PROG_NAME <command>
There are some commands:
  s, start
  t, stop
  r, restart
  p, pid
"""
}

debug() {
  [ "$DEBUG" = "1" ] && echo $1
}

set_pid() {
  CURR_PID=
  if [ -f "$PIDF" ]; then
    pid=$(cat "$PIDF")
    debug "Using ${PIDF}. Got ${pid}"
    if ps $pid > /dev/null
    then
      CURR_PID="$pid"
    fi
  fi
  if [ "$CURR_PID" = "" ]
  then
    if [ "$PGREP" = "" ]
    then
      debug "Using ps"
      CURR_PID=$(ps -ef | grep "${APP}" | grep -v grep | grep -v "$$" | awk '{print$2}')
    else
      debug "Using ${PGREP} -f '${APP}' | grep -v '$$'"
      CURR_PID=$(${PGREP} -f "${APP}" | grep -v "$$")
    fi
  fi
}

run_app() {
  set_pid
  if [ "$CURR_PID" = "" ]
  then
    echo "Run (${APP})"
    ${NOHUP} ${APP} >${STD_OUTF} 2>&1 &
    pid=$!
    rc=$?
    if [ "$rc" = "0" ]; then
      echo "Run succeed ($pid)"
      echo "$pid" > $PIDF
    else
      echo "Run failed with ($rc)"
      exit 3
    fi
  else
    echo "Running in $CURR_PID"
  fi
}

stop_app() {
  set_pid
  if [[ ! $CURR_PID ]]; then
    echo "No ${APP} process!"
    return
  fi
  echo "Stopping... process"
  if ps $CURR_PID > /dev/null
  then
    kill "$CURR_PID"
    echo -e "Stopping.."
  fi
}

start() {
  run_app
}

stop() {
  stop_app
}

case "$ACTION" in
s|start)
  start
  ;;
t|stop)
  stop
  ;;
p|pid)
  set_pid
  echo "Current running in $CURR_PID"
  ;;
*)
  usage
  exit 1
  ;;
esac
