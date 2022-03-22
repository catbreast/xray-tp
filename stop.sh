#删除转发规则
iptables -t nat -D DNS -p udp --dport 53 -j REDIRECT --to-ports 1053
iptables -t nat -D OUTPUT -m owner ! --gid-owner 23333 -j DNS
iptables -t mangle -D XRAY_MASK
iptables -t mangle -D OUTPUT -j XRAY_MASK
iptables -t mangle -D XRAY
iptables -t mangle -D PREROUTING -j XRAY
iptables -t mangle -F XRAY_MASK
iptables -t mangle -F XRAY
iptables -t nat -F DNS
iptables -t mangle -X XRAY
iptables -t mangle -X XRAY_MASK
iptables -t nat -X DNS
#删除链表
ip rule del fwmark 1 table 100
#删除路由
ip route flush table 100
#####查找xray进程并杀死
ps -ef | grep xray | grep -v grep | awk '{print $2}' | xargs kill -9
