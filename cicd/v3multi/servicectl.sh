#!/bin/bash

# # Install
#
# ## Project local install
# curl -o servicectl https://raw.githubusercontent.com/JonasGao/my-configs/master/cicd/v3multi/servicectl.sh
#
# ## Global install
# curl -o appctl https://raw.githubusercontent.com/JonasGao/my-configs/master/cicd/v3multi/servicectl.sh
# install appctl /usr/local/bin
# rm appctl

# 先存一个当前路径，说不定后边要用
CD=$(pwd)

# 工作空间
WD="$CD"

# 当前脚本的名字
PROG_NAME=$0

# 当前脚本的操作参数
ACTION="$1"

# 应用的工作目录
APP_HOME=$(cd $2; pwd)

# 应用目录名称
APP_NAME=$(basename $WD/$APP_NAME)

# 日志输出目录
LOG_HOME="${APP_HOME}/logs"

# 程序库目录
LIB_HOME="${APP_HOME}/lib"

# 配置目录
CONF_HOME="${APP_HOME}/conf"

# 应用名称
[ -z "$JAR_NAME" ] && JAR_NAME="app"

# 应用启动的端口
[ -z "$APP_PORT" ] && APP_PORT=8080

# JVM 配置参数
[ -z "$JVM_OPTS" ] && JVM_OPTS="-server -Xmx512m -XX:+UseG1GC -XX:+HeapDumpOnOutOfMemoryError -XX:HeapDumpPath=$APP_HOME/logs/"

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
JAR_PATH="${LIB_HOME}/${JAR_NAME}.jar"

# 应用的控制台输出
STD_OUT="${LOG_HOME}/std.out"

# 应用的日志文件
APP_LOG=${STD_OUT}

# PID 位置
PID_PATH="${CONF_HOME}/pid"

# 需要初始化的目录
INIT_DIRS=($APP_HOME $LOG_HOME $CONF_HOME $LIB_HOME)

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

if [[ "$TERM" == xterm* ]]; then
  print-step()  { printf "\r%s" "$1"; }
  start-step()  { printf "\r%s" "$1"; }
  append-step() { printf "%s" "$1"; }
  finish-step() { printf "\r%s\n" "$1"; }
else
  print-step()  { printf "%s\n" "$1"; }
  start-step()  { printf "%s" "$1"; }
  append-step() { printf "%s\n" "$1"; }
  finish-step() { printf "%s\n" "$1"; }
fi

curlerr() {
  case $1 in
    7) printf "Failed to connect() to host or proxy." ;;
    *) printf "CURL return %s" "$1" ;;
  esac
}

health-check() {
  if [ "$HEALTH_CHECK" = "1" ]; then
    echo "Health check disabled"
    return
  fi
  exp_time=0
  echo "Health checking ${HEALTH_CHECK_URL}"
  while true; do
    start-step "$exp_time."
    if status_code=$(/usr/bin/curl -L -o /dev/null --connect-timeout 5 -s -w "%{http_code}" "${HEALTH_CHECK_URL}"); then
      append-step " Http respond $status_code"
      for code in "${HEALTH_HTTP_CODE[@]}"
      do
        if [ "$status_code" == "$code" ]; then
          break 2
        fi
      done
    else
      append-step " $(curlerr $?)"
    fi

    sleep 1
    ((exp_time++))

    if [ "$exp_time" -gt ${APP_START_TIMEOUT} ]; then
      finish-step "App start failed. try tail application log."
      tail ${APP_LOG}
      exit 2
    fi
  done
  finish-step "Health check ${HEALTH_CHECK_URL} success."
}

print-info() {
  echo "Working Directory: $(pwd)"
  echo "Using:"
  echo "  nohup: $NOHUP"
  echo "  java:  $JAVA"
  echo "  opts:  ${JVM_OPTS}"
  echo "  jar:   ${JAR_PATH}"
  echo "  args:  ${JAR_ARGS}"
}

start-application() {
  query-java-pid
  if [ "$CURR_PID" = "" ]
  then
    if [ ! -f "$JAR_PATH" ]; then
      echo "There is no file \"$JAR_PATH\"" >&2
      exit 404
    fi
    cd "$APP_HOME"
    print-info | tee "${LOG_HOME}/version.info"
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

query-java-pid() {
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

stop-application() {
  query-java-pid

  if [[ ! $CURR_PID ]]; then
    echo "No java process!"
    return
  fi

  echo "Stopping java process ($CURR_PID)."
  times="$APP_START_TIMEOUT"
  for e in $(seq $times); do
    sleep 1
    COST_TIME=$((times - e))
    if ps $CURR_PID > /dev/null
    then
      kill "$CURR_PID"
      print-step "Stopping java lasts $COST_TIME seconds."
    else
      finish-step "Java process has exited. Remove PID \"$PID_PATH\""
      rm "$PID_PATH" > /dev/null
      return
    fi
  done
  finish-step "Java process failed exit. Still running in $CURR_PID"
  exit 4
}

start() {
  start-application
  if [ "$OTHER_RUNNING" = false ]
  then
    health-check
  fi
}

stop() {
  stop-application
}

init-dirs() {
  # 创建出相关目录
  for d in ${INIT_DIRS[@]}
  do
    mkdir -p "$d"
  done
}

update-self() {
  [ -n "$GHPROXY" ] && echo "Will use GHPROXY: $GHPROXY"
  echo "Update location: $PROG_NAME"
  curl -o $PROG_NAME "${GHPROXY}https://raw.githubusercontent.com/JonasGao/my-configs/master/cicd/v3multi/servicectl.sh"
  chmod u+x $PROG_NAME
  echo -e "\e[32mSucceed update $PROG_NAME\e[0m"
}

usage() {
  printf """Usage: $PROG_NAME <command> <service|dir name>
There are some commands:
  i, init
  d, deploy
  s, start
  t, stop
  r, restart
  p, pid
  c, check
  u, update
"""
}

# 检查参数
if [ -z "$ACTION" ]; then
  echo -e "\e[31mError: missing arguments 'command' at position 1.\e[0m"
  usage
  exit 1
fi
case "$ACTION" in
u|update)
  # Ignore #2 validation
  ;;
*)
  [ -z "$2" ] && echo -e "\e[31mError: missing arguments 'service or dir name' at position 2.\e[0m" && usage && echo 2
  ;;
esac

# 检查基本目录是否存在
if [ ! -d "$APP_HOME" ]; then
  echo "App Home not exists: $APP_HOME"
  exit 9
else
  echo "Using APP_HOME: $APP_HOME"
fi

# 创建出相关目录
init-dirs

case "$ACTION" in
d|deploy)
  if [ ! -f "$APP_HOME/${JAR_NAME}.jar" ]; then
    echo "There is no deploy target \"$APP_HOME/${JAR_NAME}.jar\""
    exit 10
  fi
  echo "Do deploy. Stop first."
  stop
  echo "Replace $JAR_PATH with $APP_HOME/${JAR_NAME}.jar"
  cp "$JAR_PATH" "${JAR_PATH}.bak"
  echo "Backup to ${JAR_PATH}.bak"
  cp "$APP_HOME/${JAR_NAME}.jar" "$JAR_PATH"
  echo "Wait 1 second."
  rm "$APP_HOME/${JAR_NAME}.jar"
  echo "Removed $APP_HOME/${JAR_NAME}.jar"
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
  query-java-pid
  echo "Current running in $CURR_PID"
  ;;
c|check)
  print-info
  health-check
  ;;
i|init)
  init-dirs
  ;;
u|update)
  update-self
  ;;
*)
  usage
  exit 1
  ;;
esac
