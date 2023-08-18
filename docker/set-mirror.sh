#!/bin/bash
# Other choise
# 2) 腾讯云 docker hub mirror
# https://mirror.ccs.tencentyun.com
# 3) 华为云
# https://05f073ad3c0010ea0f4bc00b7105ec20.mirror.swr.myhuaweicloud.com
# 4) docker中国
# https://registry.docker-cn.com
# 5) 网易
# http://hub-mirror.c.163.com
# 6) daocloud
# http://f1361db2.m.daocloud.io
sudo mkdir -p /etc/docker
sudo tee /etc/docker/daemon.json <<-'EOF'
{
  "registry-mirrors": [
      "https://registry.cn-hangzhou.aliyuncs.com/"
  ]
}
EOF
sudo systemctl daemon-reload
sudo systemctl restart docker
