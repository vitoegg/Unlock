#!/usr/bin/env bash
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH

red='\033[0;31m'
green='\033[0;32m'
yellow='\033[0;33m'
plain='\033[0m'

[[ $EUID -ne 0 ]] && echo -e "[${red}Error${plain}] 请使用root用户来执行脚本!" && exit 1

check_sys(){
    local checkType=$1
    local value=$2

    local release=''
    local systemPackage=''

    if [[ -f /etc/redhat-release ]]; then
        release="centos"
        systemPackage="yum"
    elif grep -Eqi "debian|raspbian" /etc/issue; then
        release="debian"
        systemPackage="apt"
    elif grep -Eqi "ubuntu" /etc/issue; then
        release="ubuntu"
        systemPackage="apt"
    elif grep -Eqi "centos|red hat|redhat" /etc/issue; then
        release="centos"
        systemPackage="yum"
    elif grep -Eqi "debian|raspbian" /proc/version; then
        release="debian"
        systemPackage="apt"
    elif grep -Eqi "ubuntu" /proc/version; then
        release="ubuntu"
        systemPackage="apt"
    elif grep -Eqi "centos|red hat|redhat" /proc/version; then
        release="centos"
        systemPackage="yum"
    fi

    if [[ "${checkType}" == "sysRelease" ]]; then
        if [ "${value}" == "${release}" ]; then
            return 0
        else
            return 1
        fi
    elif [[ "${checkType}" == "packageManager" ]]; then
        if [ "${value}" == "${systemPackage}" ]; then
            return 0
        else
            return 1
        fi
    fi
}

centosversion(){
    if check_sys sysRelease centos; then
        local code=$1
        local version="$(grep -oE  "[0-9.]+" /etc/redhat-release)"
        local main_ver=${version%%.*}
        if [ "$main_ver" == "$code" ]; then
            return 0
        else
            return 1
        fi
    else
        return 1
    fi
}

error_detect_depends(){
    local command=$1
    local depend=`echo "${command}" | awk '{print $4}'`
    echo -e "[${green}Info${plain}] Starting to install package ${depend}"
    ${command} > /dev/null 2>&1
    if [ $? -ne 0 ]; then
        echo -e "[${red}Error${plain}] Failed to install ${red}${depend}${plain}"
        exit 1
    fi
}

install_sniproxy(){
    for aport in 80 443; do
        netstat -a -n -p | grep LISTEN | grep -P "\d+\.\d+\.\d+\.\d+:${aport}\s+" > /dev/null && echo -e "[${red}Error${plain}] required port ${aport} already in use\n" && exit 1
    done
    
    echo "安装SNI Proxy..."
    if check_sys packageManager yum; then
        rpm -qa | grep sniproxy >/dev/null 2>&1
        if [ $? -eq 0 ]; then
            rpm -e sniproxy
        fi
    elif check_sys packageManager apt; then
        dpkg -s sniproxy >/dev/null 2>&1
        if [ $? -eq 0 ]; then
            dpkg -r sniproxy
        fi
    fi
    
    bit=`uname -m`
    cd /tmp
    
    if check_sys packageManager yum; then
        if [[ ${bit} = "x86_64" ]]; then
            wget https://github.com/myxuchangbin/dnsmasq_sniproxy_install/raw/master/sniproxy/sniproxy-0.6.1-1.el8.x86_64.rpm
            error_detect_depends "yum -y install sniproxy-0.6.1-1.el8.x86_64.rpm"
            rm -f sniproxy-0.6.1-1.el8.x86_64.rpm
        else
            echo -e "${red}暂不支持${bit}内核，请使用编译模式安装！${plain}" && exit 1
        fi
        
        if centosversion 6; then
            wget -O /etc/init.d/sniproxy https://raw.githubusercontent.com/dlundquist/sniproxy/master/redhat/sniproxy.init && chmod +x /etc/init.d/sniproxy
            [ ! -f /etc/init.d/sniproxy ] && echo -e "[${red}Error${plain}] 下载Sniproxy启动文件出现问题，请检查." && exit 1
        else
            wget -O /etc/systemd/system/sniproxy.service https://raw.githubusercontent.com/myxuchangbin/dnsmasq_sniproxy_install/master/sniproxy.service
            systemctl daemon-reload
            [ ! -f /etc/systemd/system/sniproxy.service ] && echo -e "[${red}Error${plain}] 下载Sniproxy启动文件出现问题，请检查." && exit 1
        fi
    elif check_sys packageManager apt; then
        if [[ ${bit} = "x86_64" ]]; then
            wget https://github.com/myxuchangbin/dnsmasq_sniproxy_install/raw/master/sniproxy/sniproxy_0.6.1_amd64.deb
            error_detect_depends "dpkg -i --no-debsig sniproxy_0.6.1_amd64.deb"
            rm -f sniproxy_0.6.1_amd64.deb
        else
            echo -e "${red}暂不支持${bit}内核，请使用编译模式安装！${plain}" && exit 1
        fi
        
        wget -O /etc/systemd/system/sniproxy.service https://raw.githubusercontent.com/myxuchangbin/dnsmasq_sniproxy_install/master/sniproxy.service
        systemctl daemon-reload
        [ ! -f /etc/systemd/system/sniproxy.service ] && echo -e "[${red}Error${plain}] 下载Sniproxy启动文件出现问题，请检查." && exit 1
    fi
    
    [ ! -f /usr/sbin/sniproxy ] && echo -e "[${red}Error${plain}] 安装Sniproxy出现问题，请检查." && exit 1
    
    wget -O /etc/sniproxy.conf https://raw.githubusercontent.com/myxuchangbin/dnsmasq_sniproxy_install/master/sniproxy.conf
    wget -O /tmp/sniproxy-domains.txt https://raw.githubusercontent.com/vitoegg/Unlock/main/proxy-domains.txt
    
    sed -i -e 's/\./\\./g' -e 's/^/    \.*/' -e 's/$/\$ \*/' /tmp/sniproxy-domains.txt || (echo -e "[${red}Error:${plain}] Failed to configuration sniproxy." && exit 1)
    sed -i '/table {/r /tmp/sniproxy-domains.txt' /etc/sniproxy.conf || (echo -e "[${red}Error:${plain}] Failed to configuration sniproxy." && exit 1)
    
    if [ ! -e /var/log/sniproxy ]; then
        mkdir /var/log/sniproxy
    fi
    
    echo "启动 SNI Proxy 服务..."
    if check_sys packageManager yum; then
        if centosversion 6; then
            chkconfig sniproxy on > /dev/null 2>&1
            service sniproxy start || (echo -e "[${red}Error:${plain}] Failed to start sniproxy." && exit 1)
        else
            systemctl enable sniproxy > /dev/null 2>&1
            systemctl start sniproxy || (echo -e "[${red}Error:${plain}] Failed to start sniproxy." && exit 1)
        fi
    elif check_sys packageManager apt; then
        systemctl enable sniproxy > /dev/null 2>&1
        systemctl restart sniproxy || (echo -e "[${red}Error:${plain}] Failed to start sniproxy." && exit 1)
    fi
    
    rm -rf /tmp/sniproxy-domains.txt
    echo -e "[${green}Info${plain}] sniproxy install complete..."
}

unsniproxy(){
    echo -e "[${green}Info${plain}] Stoping sniproxy services."
    if check_sys packageManager yum; then
        if centosversion 6; then
            chkconfig sniproxy off > /dev/null 2>&1
            service sniproxy stop || echo -e "[${red}Error:${plain}] Failed to stop sniproxy."
        else
            systemctl disable sniproxy > /dev/null 2>&1
            systemctl stop sniproxy || echo -e "[${red}Error:${plain}] Failed to stop sniproxy."
        fi
    elif check_sys packageManager apt; then
        systemctl disable sniproxy > /dev/null 2>&1
        systemctl stop sniproxy || echo -e "[${red}Error:${plain}] Failed to stop sniproxy."
    fi
    
    echo -e "[${green}Info${plain}] Starting to uninstall sniproxy services."
    if check_sys packageManager yum; then
        yum remove sniproxy -y > /dev/null 2>&1
        if [ $? -ne 0 ]; then
            echo -e "[${red}Error${plain}] Failed to uninstall ${red}sniproxy${plain}"
        fi
    elif check_sys packageManager apt; then
        apt-get remove sniproxy -y > /dev/null 2>&1
        if [ $? -ne 0 ]; then
            echo -e "[${red}Error${plain}] Failed to uninstall ${red}sniproxy${plain}"
        fi
    fi
    
    rm -rf /etc/sniproxy.conf
    echo -e "[${green}Info${plain}] services uninstall sniproxy complete..."
}

confirm(){
    echo -e "${yellow}是否继续执行?(n:取消/y:继续)${plain}"
    read -e -p "(默认:取消): " selection
    [ -z "${selection}" ] && selection="n"
    if [ ${selection} != "y" ]; then
        exit 0
    fi
}

if [[ $# = 1 ]];then
    key="$1"
    case $key in
        -is|--installsniproxy)
        install_sniproxy
        ;;
        -us|--unsniproxy)
        confirm
        unsniproxy
        ;;
        *)
        echo "Usage: $0 [-is|--installsniproxy] [-us|--unsniproxy]"
        ;;
    esac
else
    echo "Usage: $0 [-is|--installsniproxy] [-us|--unsniproxy]"
fi
