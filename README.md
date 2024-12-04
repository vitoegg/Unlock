> [!NOTE]
> 项目完全参考自 https://github.com/bingotl/dns_unlock 和 https://github.com/myxuchangbin/dnsmasq_sniproxy_install ，仅替换其中的Domain List为自用的纯AI列表；感谢他们的付出！


### 1.仅安装SNIProxy
```
wget --no-check-certificate -O dnsmasq_sniproxy.sh https://raw.githubusercontent.com/vitoegg/Unlock/main/dnsmasq_sniproxy.sh && bash dnsmasq_sniproxy.sh -fs
```

### 2. 修改代理域名列表
```
nano /etc/sniproxy.conf
```
如果是需要长期新增的域名，同步在域名列表中增加



### 3. 常用的命令

卸载SNIProxy
```
bash dnsmasq_sniproxy.sh -us
```

服务类命令

```
systemctl start sniproxy && systemctl enable sniproxy
```
```
systemctl stop sniproxy && systemctl disable sniproxy
```
```
systemctl restart sniproxy && systemctl status sniproxy
```
入站规则：禁止外部所有ip访问本机80/443端口（执行一次就行）
```
iptables -I INPUT -p tcp --dport 443 -j DROP
```
```
iptables -I INPUT -p tcp --dport 80 -j DROP
```

入站规则：放行某个ip访问80/443端口（按需添加）
```
iptables -I INPUT -s 线路机ip -p tcp --dport 443 -j ACCEPT
```
```
iptables -I INPUT -s 线路机ip -p tcp --dport 80 -j ACCEPT
```
