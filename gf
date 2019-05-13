#!/bin/bash

. functions/gf_function

case $1 in

#########################################[run]#########################################
#后台启动go-filecoin
run)
/usr/bin/nohup $(gf daemon) &
;;



########################################[network]######################################

#查看已经连接的网络
lsnet)
gf id | /usr/bin/jq -r '.Addresses[]'
;;

#连接网络
cnt)
gf swarm connect $2
;;

#获取peer ID
pid)
echo $PID
;;



#########################################[wallet]######################################
#查看余额
lsw)
wallet_addr=${2:-$DWA}
gf wallet balance $wallet_addr
;;

#获取默认钱包地址
dwa)
echo $DWA
;;


#列出所有钱包地址
lswa)
gf address ls
;;

#列出所有钱包余额
lswb)
index=1
for addr in `gf address ls`
do
	echo  -e  "$index   $addr   \c" 
	gf wallet balance $addr
	let index++
done
;;

#导入钱包
imp)
gf wallet import  $2
;;


#导出钱包
exp)
key_file=""
index=1
if [ ! -d ${KEY_PATH} ];then
	echo ${KEY_PATH}
	/usr/bin/mkdir ${KEY_PATH}
fi
##生成key文件名
while :
do
	if [ ! -f ${KEY_PATH}/${KEY_NAME}_${index} ];then
		key_file=${KEY_PATH}/${KEY_NAME}_${index}
		break
	fi
	let index++
done


gf wallet export $2 --enc=json > $key_file
echo $key_file
;;


#转账
send)
if [ $# -le 3 ];then
	
	len1=$(/usr/bin/echo $2 | /usr/bin/wc -L) 
	len2=$(/usr/bin/echo $3 | /usr/bin/wc -L)
	echo $len1 $len2

	if [ $len1 -eq 41 ] && [ $len2 -eq 41 ] && [ "$2" != "$3" ];then
		src_wallet_addr=$2
                dest_wallet_addr=$3
                value=${4:-1000}
	else
		src_wallet_addr=$DWA
		dest_wallet_addr=$2
		value=${3:-1000}
	fi

else
	src_wallet_addr=$2
	dest_wallet_addr=$3
	value=${4:-1000}
fi
echo $src_wallet_addr  $dest_wallet_addr $value
gf message send --from ${src_wallet_addr} --gas-price=0 --gas-limit=300 --value $value ${dest_wallet_addr}
;;



#########################################[minwer]######################################
#获取miner ID
mid)
echo $MID
;;

#开启矿工
cm)
rom=${2:-10}
fil=${3:-100}
gf miner create ${rom} ${fil} --gas-price=0 --gas-limit=1000 --peerid ${PID}
gf mining start
;;

#生成订单
ca)
wallet_addr=${2:-$DWA}
price=${3:-0.000000000001}

gf miner set-price --from=$wallet_addr --miner=$MID --gas-price=0 --gas-limit=1000 $price 288000
;;


#查看算力
pow)
miner_id=${2:-$MID}
gf miner power $miner_id
;;



#########################################[client]######################################

#列出所有订单
ls)
gf client list-asks --enc=json
;;

#生成CID
cid)
gf client import $2
;;

#查看订单状态
deal)
gf client query-storage-deal $2
;;

#提交订单
cmt)
ask=${4:-0}
duration=${5:-1000}
cid=$(gf client import $3)
gf client propose-storage-deal $2 $cid $ask $duration
;;

#########################################[other]######################################
-h)
echo '----------------------------------命令帮助-----------------------------------------------

命令			参数				说明
---run---
run			-				后台运行节点

---network---
pid			-				获取peer ID
lsnet			-				查看已经连接的网络
cnt			<gf_ip>				连接到filecoin网络

---wallet---
lsw			[wallet_addr]			查看钱包余额，不填即默认钱包
lswa			-				列出所有钱包地址
dwa			-				获取默认钱包地址
lswb			-				查询所有钱包的余额信息
imp			<path>				导入钱包
exp			<wallet_addr>			导出钱包
send			[src] <dest> <val>		转账sec="默认钱包地址",val="1000"

---miner---
mid			-				获取miner ID
cm			[rom] [fil]			开启矿工
ca			[wallet_addr][price]		生成订单,默认dwa,0.000000000001
pow			[miner_id]			查看算力,默认为自身id

---client---
ls			-				列出所有订单
cid			<path>				生成CID
deal			<zid>				查看订单状态
cmt			<mid><path>[ask][duration]	提交订单ask=0,duration=1000	

---other---
-h			-				查看帮助文档
-			-				官方命令
----------------------------------------------------------------------------------------
'
;;

*)
gf $*
;;

esac
