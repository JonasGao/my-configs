#!/bin/bash

APP_NAME="xxxxxxxxxxx"

# 应用启动的端口
APP_PORT=9909

# JVM 配置参数
JVM_OPTS="-ea -server"

# JAR 包启动的时候传递的参数
JAR_ARGS=""

# 当前脚本的名字
PROG_NAME=$0

# 当前脚本的操作参数
ACTION=$1

# 等待应用启动的时间
APP_START_TIMEOUT=20

# 应用健康检查URL
HEALTH_CHECK_URL=http://127.0.0.1:${APP_PORT}

# 应用启动的工作目录
APP_HOME=/home/deployer/${APP_NAME}

# JAR 包的绝对路径
JAR_NAME=${APP_HOME}/${APP_NAME}.jar # jar包的名字

# 应用的控制台输出
# 例如 JAVA_OUT=${APP_HOME}/logs/start.log
JAVA_OUT=/dev/null

# 应用的日志输出路径
APP_LOG_HOME=${APP_HOME}/logs

# 创建出相关目录
mkdir -p ${APP_HOME}
mkdir -p ${APP_LOG_HOME}

usage() {
    echo "Usage: $PROG_NAME {start|stop|restart}"
}

health_check() {
    exptime=0
    echo "checking ${HEALTH_CHECK_URL}"
    while true
        do
            status_code=$(/usr/bin/curl -L -o /dev/null --connect-timeout 5 -s -w "%{http_code}" ${HEALTH_CHECK_URL})
            if [ "$?" != "0" ]; then
               echo "application not started"
            else
                echo "code is $status_code"
                if [ "$status_code" == "200" ] || [ "$status_code" == "404" ] || [ "$status_code" == "405" ];then
                    break
                fi
            fi
            sleep 1
            ((exptime++))

            echo "wait app to pass health check: $exptime..."

            if [ $exptime -gt ${APP_START_TIMEOUT} ]; then
                echo 'app start failed. try tail application log'
                tail ${APP_LOG_HOME}/app.log
               exit 1
            fi
        done
    echo "check ${HEALTH_CHECK_URL} success"
}

start_application() {
    echo "starting java process (${JAR_NAME})"
    nohup java ${JVM_OPTS} -jar ${JAR_NAME} ${JAR_ARGS} > ${JAVA_OUT} 2>&1 &
    echo "started java process"
}

stop_application() {
   checkjavapid=`ps -ef | grep java | grep ${APP_NAME} | grep -v grep |grep -v 'deploy.sh'| awk '{print$2}'`

   if [[ ! $checkjavapid ]];then
      echo -e "\rno java process"
      return
   fi

   echo "stop java process"
   times=60
   for e in $(seq 60)
   do
        sleep 1
        COSTTIME=$(($times - $e ))
        checkjavapid=`ps -ef | grep java | grep ${APP_NAME} | grep -v grep |grep -v 'deploy.sh'| awk '{print$2}'`
        if [[ $checkjavapid ]];then
            kill -9 $checkjavapid
            echo -e "\r        -- stopping java lasts `expr $COSTTIME` seconds."
        else
            echo -e "\rjava process has exited"
            break;
        fi
   done
   echo ""
}

start() {
    start_application
    health_check
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
    *)
        usage
        exit 1
    ;;
esac
