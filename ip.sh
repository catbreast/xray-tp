lan1=`ip address | grep -w inet | awk '{print $2}' | sed -n '1,1p'`
lan2=`ip address | grep -w inet | awk '{print $2}' | sed -n '2,1p'`

ulimit -SHn 1000000
/data/adb/magisk/busybox setuidgid 0:23333 /data/adb/xray/xray run -confdir /data/adb/xray/conf &


ip route add local default dev lo table 100 # 添加路由表 100
ip rule add fwmark 1 table 100 # 为路由表 100 设定规则

# 代理局域网设备
iptables -t mangle -N XRAY
#  "网关所在ipv4网段" 通过运行命令"ip address | grep -w inet | awk '{print $2}'"获得，一般有多个
iptables -t mangle -A XRAY -d $lan1 -j RETURN
iptables -t mangle -A XRAY -d $lan2 -j RETURN


# 组播地址/E类地址/广播地址直连
iptables -t mangle -A XRAY -d 224.0.0.0/3 -j RETURN


#如果网关作为主路由，则加上这一句，见：https://xtls.github.io/documents/level-2/transparent_proxy/transparent_proxy.md#iptables透明代理的其它注意事项
#网关LAN_IPv4地址段，运行命令"ip address | grep -w "inet" | awk '{print $2}'"获得，是其中的一个
iptables -t mangle -A XRAY ! -s $lan2 -j RETURN

# 给 TCP 打标记 1，转发至 12345 端口
# mark只有设置为1，流量才能被Xray任意门接受
iptables -t mangle -A XRAY -p tcp -j TPROXY --on-port 12345 --tproxy-mark 1
iptables -t mangle -A XRAY -p udp -j TPROXY --on-port 12345 --tproxy-mark 1
# 应用规则
iptables -t mangle -A PREROUTING -j XRAY

# 代理网关本机
iptables -t mangle -N XRAY_MASK
iptables -t mangle -A XRAY_MASK -m owner --gid-owner 23333 -j RETURN
#绕过应用
iptables -t mangle -A XRAY_MASK -m owner --uid-owner 10287 -j RETURN
iptables -t mangle -A XRAY_MASK -d $lan1 -j RETURN
iptables -t mangle -A XRAY_MASK -d $lan2 -j RETURN

iptables -t mangle -A XRAY_MASK -d 224.0.0.0/3 -j RETURN
iptables -t mangle -A XRAY_MASK -j MARK --set-mark 1
iptables -t mangle -A OUTPUT -p tcp -j XRAY_MASK
iptables -t mangle -A OUTPUT -p udp -j XRAY_MASK
##dns
iptables -t nat -N DNS
iptables -t nat -A DNS -p udp --dport 53 -j REDIRECT --to-ports 1053
iptables -t nat -A DNS -p tcp --dport 53 -j REDIRECT --to-ports 1053
iptables -t nat -I OUTPUT -m owner ! --gid-owner 23333 -j DNS
