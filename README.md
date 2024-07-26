# Unlock
主要目的是通过解锁机的能力，让线路机具备OpenAI稳定解锁的能力
项目完全参考自https://github.com/bingotl/dns_unlock和https://github.com/myxuchangbin/dnsmasq_sniproxy_install，仅替换其中的Domain List为自用的纯AI列表；


## 一、解锁机：安装sniproxy

### 1.安装SNIProxy
```
wget --no-check-certificate -O dnsmasq_sniproxy.sh https://raw.githubusercontent.com/myxuchangbin/dnsmasq_sniproxy_install/master/dnsmasq_sniproxy.sh && bash dnsmasq_sniproxy.sh -fs
```

### 2. 修改代理域名列表
```
nano /etc/sniproxy.conf
```
如果是需要长期新增的域名，同步在域名列表中增加

## 二、线路机：安装dnsmasq

### 1.安装DNSmasq
```
wget --no-check-certificate -O unlock.sh https://raw.githubusercontent.com/bingotl/dns_unlock/main/unlock.sh && chmod +x unlock.sh
```
```
./unlock.sh 解锁机IP
```
### 2.域名修改
```
nano /etc/dnsmasq.d/unlock.conf
```
## 三、常用的命令

取消解锁：
```
./unlock.sh r
```

服务类命令
```
systemctl start dnsmasq && systemctl enable dnsmasq
```
```
systemctl stop dnsmasq && systemctl disable dnsmasq
```
```
systemctl restart dnsmasq && systemctl status dnsmasq
```
```
systemctl start sniproxy &&systemctl enable sniproxy
```
```
systemctl stop sniproxy && systemctl disable sniproxy
```
```
systemctl restart sniproxy && systemctl status sniproxy
```

入站规则：放行某个ip访问80/443端口（按需添加）
```
iptables -I INPUT -s 线路机ip -p tcp --dport 443 -j ACCEPT
```
```
iptables -I INPUT -s 线路机ip -p tcp --dport 80 -j ACCEPT
```

> [!IMPORTANT]
> https://github.com/bingotl/dns_unlock
> https://github.com/myxuchangbin/dnsmasq_sniproxy_install
