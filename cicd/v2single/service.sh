#!/bin/bash

CWD=$(pwd)

# 当前脚本的名字
PROG_NAME=$0

# 当前脚本的操作参数
ACTION=$1

# 应用启动的工作目录
APP_HOME="$CWD"

JAR_NAME="app"

# 应用启动的端口
APP_PORT=8090

# JVM 配置参数
JVM_OPTS="-server -Xmx512m"

# JAR 包启动的时候传递的参数
JAR_ARGS="--spring.config.location=file:conf/"

# 等待应用启动的时间
APP_START_TIMEOUT=20

# 应用健康检查URL
HEALTH_CHECK_URL="http://127.0.0.1:${APP_PORT}"

# 健康的HTTP代码
HEALTH_HTTP_CODE=(200 404 403 405)

# JAR 包的绝对路径
JAR_PATH="${APP_HOME}/${JAR_NAME}.jar"

# 应用的控制台输出
# 例如 STD_OUT=${APP_HOME}/logs/start.log
STD_OUT="${APP_HOME}/app.log"

# 应用的日志输出路径
APP_LOG_HOME=${APP_HOME}

# 应用的日志文件
APP_LOG=${STD_OUT}

# PID 位置
PID="${APP_HOME}/pid"

# 准备相关工具
JAVA=$(which java 2>/dev/null)
NOHUP=$(which nohup 2>/dev/null)
PGREP=$(which pgrep 2>/dev/null)

# 环境配置文件名
SET_ENV_FILENAME="setenv.sh"

# 如果有配置文件，以配置文件覆盖
CWD_SET_ENV=$(readlink -f "./$SET_ENV_FILENAME")
if [ -f "$CWD_SET_ENV" ]; then
  echo "Overwrite with $CWD_SET_ENV"
  source $CWD_SET_ENV
fi
APP_HOME_SET_ENV="$APP_HOME/$SET_ENV_FILENAME"
if [ -f "$APP_HOME_SET_ENV" ]; then
  if [ "$APP_HOME_SET_ENV" != "$CWD_SET_ENV" ]; then
    echo "Overwrite with $APP_HOME_SET_ENV"
    source $APP_HOME_SET_ENV
  fi
fi

# 创建出相关目录
mkdir -p ${APP_HOME}
mkdir -p ${APP_LOG_HOME}

# 全局变量
CURR_PID=
OTHER_RUNNING=false

usage() {
  printf """Usage: $PROG_NAME <command>
There are some commands:
  s, start
  t, stop
  r, restart
  p, pid
  c, check
"""
}

health_check() {
  if [ "$HEALTH_CHECK" = "1" ]; then
    echo "Health check disabled"
    return
  fi
  exp_time=0
  echo "Checking ${HEALTH_CHECK_URL}"
  while true; do
    if status_code=$(/usr/bin/curl -L -o /dev/null --connect-timeout 5 -s -w "%{http_code}" ${HEALTH_CHECK_URL}); then
      echo "Status-code is $status_code"
      for code in ${HEALTH_HTTP_CODE[@]}
      do
        if [ "$status_code" == "$code" ]; then
          break 2
        fi
      done
    else
      printf "curl return $?. "
    fi

    sleep 1
    ((exp_time++))
    echo "Waiting to health check: $exp_time..."

    if [ "$exp_time" -gt ${APP_START_TIMEOUT} ]; then
      echo 'app start failed. try tail application log'
      tail ${APP_LOG}
      exit 2
    fi
  done
  echo "Health check ${HEALTH_CHECK_URL} success"
}

start_application() {
  query_java_pid
  if [ "$CURR_PID" = "" ]
  then
    if [ ! -f "$JAR_PATH" ]; then
      echo "There is no file \"$JAR_PATH\"" >&2
      exit 404
    fi
    echo "Run (${JAR_PATH})"
    ${NOHUP} ${JAVA} ${JVM_OPTS} -jar ${JAR_PATH} ${JAR_ARGS} >${STD_OUT} 2>&1 &
    pid=$!
    rc=$?
    if [ "$rc" = "0" ]; then
      echo "Run jar succeed ($pid)"
      echo "$pid" > $PID
    else
      echo "Run jar failed with ($rc)"
      exit 3
    fi
  else
    echo "Running in $CURR_PID"
    OTHER_RUNNING=true
  fi
}

debug() {
  [ "$DEBUG" = "1" ] && echo $1
}

query_java_pid() {
  CURR_PID=
  if [ -f "$PID" ]; then
    pid=$(cat "$PID")
    debug "Using ${PID}. Got ${pid}"
    if ps $pid > /dev/null
    then
      CURR_PID="$pid"
    fi
  fi
  if [ "$CURR_PID" = "" ]
  then
    target=${JAR_PATH}
    if [ "$PGREP" = "" ]
    then
      debug "Using ps"
      CURR_PID=$(ps -ef | grep java | grep "${target}" | grep -v grep | grep -v "$$" | awk '{print$2}')
    else
      debug "Using ${PGREP} -f '${target}' | grep -v '$$'"
      CURR_PID=$(${PGREP} -f "${target}" | grep -v "$$")
    fi
  fi
}

stop_application() {
  query_java_pid

  if [[ ! $CURR_PID ]]; then
    echo "No java process!"
    return
  fi

  echo "Stopping java process"
  times=60
  for e in $(seq $times); do
    sleep 1
    COST_TIME=$((times - e))
    if ps $CURR_PID > /dev/null
    then
      kill "$CURR_PID"
      echo -e "  -- stopping java lasts ${COST_TIME} seconds."
    else
      echo -e "Java process has exited"
      break
    fi
  done
}

start() {
  start_application
  if [ "$OTHER_RUNNING" = false ]
  then
    health_check
  fi
}

stop() {
  stop_application
}

case "$ACTION" in
s|start)
  start
  ;;
t|stop)
  stop
  ;;
r|restart)
  stop
  start
  ;;
p|pid)
  query_java_pid
  echo "Current running in $CURR_PID"
  ;;
c|check)
  health_check
  ;;
*)
  usage
  exit 1
  ;;
esac
