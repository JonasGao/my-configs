#!/bin/bash

APP_NAME="eureka"

# 应用启动的端口
APP_PORT=7761

# JVM 配置参数
JVM_OPTS="-server -Xmx512m"

# JAR 包启动的时候传递的参数
JAR_ARGS=""

# 当前脚本的名字
PROG_NAME=$0

# 当前脚本的操作参数
ACTION=$1

# 等待应用启动的时间
APP_START_TIMEOUT=20

# 应用健康检查URL
HEALTH_CHECK_URL="http://127.0.0.1:${APP_PORT}"

# 应用启动的工作目录
APP_HOME="/home/deployer/retail-cloud/eureka"

# JAR 包的绝对路径
JAR_PATH="${APP_HOME}/eureka-server.jar"

# 应用的控制台输出
# 例如 STD_OUT=${APP_HOME}/logs/start.log
STD_OUT="${APP_HOME}/app.log"

# 应用的日志输出路径
APP_LOG_HOME=${APP_HOME}

# 应用的日志文件
APP_LOG=${STD_OUT}

# PID 位置
PID="${APP_HOME}/pid"

# 创建出相关目录
mkdir -p ${APP_HOME}
mkdir -p ${APP_LOG_HOME}

# 准备相关工具
JAVA=$(which java)
NOHUP=$(which nohup)
PGREP=$(which pgrep1 2>/dev/null)

# 全局变量
CURR_PID=
OTHER_RUNNING=false

usage() {
  echo "Usage: $PROG_NAME {start|stop|restart|pid}"
}

health_check() {
  exp_time=0
  echo "Checking ${HEALTH_CHECK_URL}"
  while true; do
    if status_code=$(/usr/bin/curl -L -o /dev/null --connect-timeout 5 -s -w "%{http_code}" ${HEALTH_CHECK_URL}); then
      echo "Status-code is $status_code"
      if [ "$status_code" == "200" ] || [ "$status_code" == "404" ] || [ "$status_code" == "405" ]; then
        break
      fi
    else
      echo "Application not started"
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

query_java_pid() {
  if [ -f "$PID" ]; then
    pid=$(cat "$PID")
    if ps -p $PID > /dev/null
    then
      CURR_PID="$pid"
    fi
  fi
  if [ "$CURR_PID" = "" ]
  then
    target=${APP_NAME}
    if [ "$PGREP" = "" ]
    then
      CURR_PID=$(ps -ef | grep java | grep "${target}" | grep -v grep | grep -v "$$" | awk '{print$2}')
    else
      CURR_PID=$(${PGREP} -lf "${target}" | grep -v "$$")
    fi
  fi
}

stop_application() {
  check_java_pid=$(query_java_pid)

  if [[ ! $check_java_pid ]]; then
    echo "No java process!"
    return
  fi

  echo "Stopping java process"
  times=60
  for e in $(seq 60); do
    sleep 1
    COST_TIME=$((times - e))
    check_java_pid=$(query_java_pid)
    if [[ $check_java_pid ]]; then
      kill -9 "$check_java_pid"
      echo -e "        -- stopping java lasts ${COST_TIME} seconds."
    else
      echo -e "Java process has exited"
      break
    fi
  done
}

start() {
  start_application
  if [ ! $OTHER_RUNNING ]
  then
    health_check
  fi
}

stop() {
  stop_application
}

case "$ACTION" in
start)
  start
  ;;
stop)
  stop
  ;;
restart)
  stop
  start
  ;;
pid)
  query_java_pid
  echo "Current running in $CURR_PID"
  ;;
*)
  usage
  exit 1
  ;;
esac

