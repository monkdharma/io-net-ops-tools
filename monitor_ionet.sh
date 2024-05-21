#!/bin/bash

# io_net_launch_binary_linux 二进制程序终端运行时输出的授权链接
# 验证成功后会输出一个 token 后续设备加入 io 网络都可以使用同一个 token 通过 --token 传入 
TOKEN=""

# WORKERDIR 定义存放 io_net_launch_binary_linux 二进制程序的目录
WORKERDIR=""

if ! command -v jq &>/dev/null; then
  apt update -y && apt install jq -y
fi

function start_ionet() {
	current_datetime=$(date +"%Y-%m-%d %H:%M:%S")
  echo "[$current_datetime] [INFO] trigger a container restart." >> ${WORKERDIR}/ionet.log

	for i in `docker ps -aq`;do docker stop $i && docker rm $i;done
  
  USER_ID=$(cat ${WORKERDIR}/ionet_device_cache.json|jq -r '.user_id')
	DEVICE_ID=$(cat ${WORKERDIR}/ionet_device_cache.json|jq -r '.device_id')
	DEVICE_NAME=$(cat ${WORKERDIR}/ionet_device_cache.json|jq -r '.device_name')

	cd ${WORKERDIR}
	echo Yes|./io_net_launch_binary_linux --device_id=${DEVICE_ID} --user_id=${USER_ID} --operating_system="Linux" --usegpus=true --device_name=${DEVICE_NAME}	
}

# 如果 GPU 有掉卡的错误重启系统
NVIDIA_FAILED=$(nvidia-smi|grep Error)
if [ $? -eq 0 ];then
	/usr/sbin/shutdown -r now
fi


CONTAINERS_COUNT=$(docker ps -aq|wc -l)

if [ $CONTAINERS_COUNT -lt 2 ];then
	start_ionet
fi

# 检查容器状态
monitor_running=$(docker ps | grep -c "io-worker-monitor")
vc_running=$(docker ps | grep -c "io-worker-vc")
launch_running=$(docker ps | grep -c "io-launch")
# 第一种重启规则: monitor和vc没起来，且launch容器也没起来
if [[ monitor_running -eq 0 && vc_running -eq 0 && launch_running -eq 0 ]]; then
  start_ionet
fi

# 第二种,monitor和vc 有一个没起来
if [[ monitor_running -eq 0 || vc_running -eq 0 ]]; then
	start_ionet
fi

# 检查io-launch容器是否存在并且运行时间大于1小时
io_launch_info=$(docker ps --format '{{.Image}} {{.Status}}' | grep "io-launch")
if [[ ! -z "$io_launch_info" && "$io_launch_info" == *"hour"* ]]; then
	start_ionet
fi