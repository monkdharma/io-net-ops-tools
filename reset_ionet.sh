#!/bin/bash
# reset_ionet 脚本配合 ansible 实现批量重启所有 io.net 节点

# io_net_launch_binary_linux 二进制程序终端运行时输出的授权链接
# 验证成功后会输出一个 token 后续设备加入 io 网络都可以使用同一个 token 通过 --token 传入 
TOKEN=""
# 存放 io_net_launch_binary_linux 二进制程序的目录
WORKERDIR=""


if [ -f ${WORKERDIR}/io_net_launch_binary_linux ];then
  rm -f ${WORKERDIR}/io_net_launch_binary_linux
  cd ${WORKERDIR}
  curl -L https://github.com/ionet-official/io_launch_binaries/raw/main/io_net_launch_binary_linux -o io_net_launch_binary_linux
  chmod +x io_net_launch_binary_linux
fi

if ! command -v jq &>/dev/null; then
  apt update -y && apt install jq -y
fi

for i in `docker ps -aq`;do docker stop $i && docker rm $i;done

USER_ID=$(cat ${WORKERDIR}/ionet_device_cache.json|jq -r '.user_id')
DEVICE_ID=$(cat ${WORKERDIR}/ionet_device_cache.json|jq -r '.device_id')
DEVICE_NAME=$(cat ${WORKERDIR}/ionet_device_cache.json|jq -r '.device_name')

cd ${WORKERDIR}
echo Yes|./io_net_launch_binary_linux --device_id=${DEVICE_ID} --user_id=${USER_ID} --operating_system="Linux" --usegpus=true --device_name=${DEVICE_NAME}