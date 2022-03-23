#删除转发
iptables -t nat -F DNS
iptables -t nat -F OUTPUT
iptables -t mangle -F OUTPUT
iptables -t mangle -F XRAY_MASK
iptables -t mangle -F PREROUTING
iptables -t mangle -F XRAY
iptables -t nat -X DNS
iptables -t mangle -X XRAY_MASK
iptables -t mangle -X XRAY
#删除链表
ip rule del fwmark 1 table 100
#删除路由
ip route flush table 100
#####查找xray进程并杀死
ps -ef | grep xray | grep -v grep | awk '{print $2}' | xargs kill -9
