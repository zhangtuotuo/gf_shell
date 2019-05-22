#!/bin/bash

. functions/gf_function

case $1 in

#########################################[run]#########################################

#初始化节点
ini)
version=${2:-test}
ini $version
;;

#后台启动go-filecoin
run)
run
;;

#重启节点
restart)
restart_node $2 $3
;;

#强行关闭进程
kill_gf)
kill_gf $2
;;


########################################[network]######################################

#获取本机IP
lsip)
gf id | /usr/bin/jq -r '.Addresses[]'
;;

#查看已经连接的网络
lsnet)
gf swarm peers
;;

#连接网络
cnt)
gf swarm connect $2
;;

#获取peer ID
pid)
get_pid
;;



#########################################[wallet]######################################
#查看余额
lsw)
wallet_addr=${2:-$(get_dwa)}
show_balance $(get_dwa)
;;

#获取默认钱包地址
dwa)
get_dwa
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
export_wallet $2
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
		src_wallet_addr=$(get_dwa)
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
get_mid
;;

#生成指定大小的测试文件
mkf)
make_file $2 $3
;;

#开启矿工
cm)
create_miner $2 $3
;;

#生成订单
ca)
create_ask $2 $3
;;


#查看算力
pow)
miner_id=${2:-$(get_mid)}
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
ini			[version]			(ol)官方版,(test)测试版,默认为"test"
run			-				后台运行节点
restart			[rm][version]			重启节点，(rm)初始化节点后重启,不初始化无需指定版本

---network---
lsip			-				获取本机IP
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
mkf			[name][size]			生成指定大小的测试文件(MB),name="test",size="250M"
cm			[rom] [fil]			开启矿工
ca			[wallet_addr][price]		生成订单,默认dwa,0.000000000001
pow			[miner_id]			查看算力,默认为自身id

---client---
ls			-				列出所有订单
cid			<path>				生成CID
deal			<zid>				查看订单状态
cmt			<mid><path>[ask][duration]	提交订单ask=0,duration=1000	

---test---
god			-				创建主网
node			-				创建节点
on			-				一键启动矿工节点

---other---
-h			-				查看帮助文档
ver			-				查看当前版本
swv			<ver>				切换gf版本[ol|test]
-			-				官方命令

----------------------------------------------------------------------------------------
'
;;


#查看当前版本
ver)
cat $VER_PATH/version
;;

#切换gf版本
swv)
ver=${2:-'test'}
if [ "$ver" == "ol" ] || [ "$ver" == "test" ];then
	update $ver
else
	echo version error!
fi
;;

#创建主网(仅适用与测试版)
god)
create_god
;;

#一键启动节点(仅适用与测试版)
node)
create_node
;;

#一键启动矿工(仅适用与测试版)
on)
on
;;

#官方命令
*)
gf $*
;;

esac
