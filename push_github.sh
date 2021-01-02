#! /bin/bash

#################################
##   @author guojiafeng        ##
#################################

# ps -ef|grep java | grep -v grep | awk '{print $2}'| xargs kill -9
## windows常用追踪命令
## windows查看端口占用
## netstat -ano|findstr "8080"
## kill进程 byid
## taskkill /F /PID 123
## kill进程 byname
## taskkill /F /IM java.exe

echo "#################################"
echo "##   @author guojiafeng        ##"
echo "##   @info   提交到Github       ##"
echo "##			     			 ##"
echo "#################################"
git config  user.email "iamgjf@qq.com"
git config  user.name "GuoJiafeng"

msg=$1
pull_msg=$2
echo "git status"
git status
echo "git add ."
git add .


sleep 1

echo "git commit -m $msg"
git commit -m "$msg"

echo "push -u origin master"
git push -u origin master

