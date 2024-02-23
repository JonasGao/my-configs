#!/bin/bash

# 先存一个当前路径，说不定后边要用
CD=$(pwd)

# 工作空间
WD="$CD"

# 当前脚本的名字
PROG_NAME=$0

# 当前脚本的操作参数
ACTION="$1"

# 应用的工作目录
APP_HOME="$2"

# 应用目录名称
APP_NAME=$(basename $WD/$APP_NAME)

# 应用名称
[ -z "$JAR_NAME" ] && JAR_NAME="app"

# 应用启动的端口
[ -z "$APP_PORT" ] && APP_PORT=8080

# JVM 配置参数
[ -z "$JVM_OPTS" ] && JVM_OPTS="-server -Xmx512m"

# JAR 包启动的时候传递的参数
JAR_ARGS="--server.port=${APP_PORT}"

# 进程启动等待时间
[ -z "$PROC_START_TIMEOUT" ] && PROC_START_TIMEOUT=3

# 等待应用启动的时间
[ -z "$APP_START_TIMEOUT" ] && APP_START_TIMEOUT=30

# 应用健康检查URL
HEALTH_CHECK_URL="http://127.0.0.1:${APP_PORT}"

# 健康的HTTP代码
HEALTH_HTTP_CODE=(200 404 403 405)

# JAR 包的绝对路径
JAR_PATH="${APP_HOME}/lib/${JAR_NAME}.jar"

# 应用的控制台输出
STD_OUT="${APP_HOME}/logs/app.log"

# 应用的日志输出路径
APP_LOG_HOME=${APP_HOME}

# 应用的日志文件
APP_LOG=${STD_OUT}

# PID 位置
PID_PATH="${APP_HOME}/conf/pid"

# 需要初始化的目录
INIT_DIRS=($APP_HOME $APP_LOG_HOME "$APP_HOME/lib" "$APP_HOME/conf" "$APP_HOME/logs")

# 准备相关工具
JAVA=$(which java 2>/dev/null)
NOHUP=$(which nohup 2>/dev/null)
PGREP=$(which pgrep 2>/dev/null)

# 环境配置文件名
SET_ENV_FILENAME="setenv.sh"

# 使用顶层 env 脚本
WDIR_SET_ENV=$(readlink -f "$WD/$SET_ENV_FILENAME")
if [ -f "$WDIR_SET_ENV" ]; then
  echo "Overwrite with $WDIR_SET_ENV"
  source $WDIR_SET_ENV
fi

# 使用各级应用 env 脚本
APP_HOME_SET_ENV="$APP_HOME/conf/$SET_ENV_FILENAME"
if [ -f "$APP_HOME_SET_ENV" ]; then
  if [ "$APP_HOME_SET_ENV" != "$WDIR_SET_ENV" ]; then
    echo "Overwrite with $APP_HOME_SET_ENV"
    source $APP_HOME_SET_ENV
  else
    echo "WARN: APP_HOME_SET_ENV same with WDIR_SET_ENV is '$APP_HOME_SET_ENV'"
  fi
fi

# 执行后置函数
if [ -n "$POST_FUNC" ]; then
  echo "Running POST_FUNC: $POST_FUNC"
  $POST_FUNC
  unset POST_FUNC
fi

# 全局变量
CURR_PID=
OTHER_RUNNING=false

usage() {
  printf """Usage: $PROG_NAME <command> <service|dir name>
There are some commands:
  d, deploy
  s, start
  t, stop
  r, restart
  p, pid
  c, check
"""
}

health_check() {
  if [ "$HEALTH_CHECK" = "0" ]; then
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
    cd "$APP_HOME"
    echo "Working Directory: $(pwd)"
    echo "Using:"
    echo "  nohup: $NOHUP"
    echo "  java:  $JAVA"
    echo "  opts:  ${JVM_OPTS}"
    echo "  jar:   ${JAR_PATH}"
    echo "  args:  ${JAR_ARGS}"
    ${NOHUP} ${JAVA} ${JVM_OPTS} -jar ${JAR_PATH} ${JAR_ARGS} >${STD_OUT} 2>&1 &
    local PID=$!
    local NOHUP_RET=$?
    local RET=99
    if [ "$NOHUP_RET" = "0" ]; then
      echo "Run nohup succeed (NOHUP RETURN: $NOHUP_RET, APP PID: $PID)"
      echo "$PID" > $PID_PATH
      echo "Wait $PROC_START_TIMEOUT second."
      sleep "$PROC_START_TIMEOUT"
      if [ ! -d "/proc/$PID" ]; then
        wait "$PID"
        RET=$?
        echo "ERROR: Run app fail. Return: $RET"
        exit 4
      fi
    else
      echo "ERROR: Run jar failed with ($NOHUP_RET)"
      exit 3
    fi
  else
    echo "Running in $CURR_PID"
    OTHER_RUNNING=true
  fi
}

query_java_pid() {
  CURR_PID=
  if [ -f "$PID_PATH" ]; then
    local pid=$(cat "$PID_PATH")
    if ps $pid > /dev/null
    then
      CURR_PID="$pid"
      echo "Got pid ($pid) from \"$PID_PATH\""
    else
      echo "PID ($pid) from \"$PID_PATH\" can not found by ps. Will search by pgrep or ps."
    fi
  fi
  if [ "$CURR_PID" = "" ]
  then
    target=${JAR_PATH}
    if [ "$PGREP" = "" ]
    then
      echo "Query process by ps"
      CURR_PID=$(ps -ef | grep java | grep "${target}" | grep -v grep | grep -v "$$" | awk '{print$2}')
    else
      echo "Query process by ${PGREP} -f \"${target}\" | grep -v \"\$\$\""
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

  echo "Stopping java process ($CURR_PID)."
  times=60
  for e in $(seq $times); do
    sleep 1
    COST_TIME=$((times - e))
    if ps $CURR_PID > /dev/null
    then
      kill "$CURR_PID"
      echo -e "  -- stopping java lasts ${COST_TIME} seconds."
    else
      echo -e "Java process has exited. Remove PID \"$PID_PATH\""
      rm "$PID_PATH" > /dev/null
      return
    fi
  done
  echo -e "Java process failed exit. Still running in $CURR_PID"
  exit 4
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

# 检查参数
if [ "$1" = "" ] || [ "$2" = "" ]; then
  usage
  exit 0
fi

# 检查基本目录是否存在
if [ ! -d "$APP_HOME" ]; then
  echo "App Home not exists: $APP_HOME"
  exit 9
else
  echo "Using APP_HOME: $APP_HOME"
fi

# 创建出相关目录
for d in ${INIT_DIRS[@]}
do
  mkdir -p "$d"
done

case "$ACTION" in
d|deploy)
  if [ ! -f "$APP_HOME/app.jar" ]; then
    echo "There is no deploy target \"$APP_HOME/app.jar\""
    exit 10
  fi
  echo "Do deploy. Stop first."
  stop
  echo "Replace $JAR_PATH with $APP_HOME/app.jar"
  cp "$JAR_PATH" "${JAR_PATH}.bak"
  echo "Backup to ${JAR_PATH}.bak"
  cp "$APP_HOME/app.jar" "$JAR_PATH"
  echo "Wait 1 second."
  rm "$APP_HOME/app.jar"
  echo "Removed $APP_HOME/app.jar"
  sleep 1
  echo "Startup..."
  start
  ;;
s|start)
  start
  ;;
t|stop)
  stop
  ;;
r|restart)
  echo "Do restart. Stop first."
  stop
  echo "Wait 1 second."
  sleep 1
  echo "Startup..."
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
