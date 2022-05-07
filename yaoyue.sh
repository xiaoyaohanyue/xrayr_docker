#!/usr/bin/env bash
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH

# Current folder
cur_dir=`pwd`
def_dir="/root"
# Color
red='\033[0;31m'
green='\033[0;32m'
yellow='\033[0;33m'
plain='\033[0m'
operation=(init bbr Exit version)
github_url="https://raw.githubusercontent.com/xiaoyaohanyue/xrayr_docker/main"
github_dw_url="https://github.com/xiaoyaohanyue/xrayr_docker/raw/main"
# Make sure only root can run our script
[[ $EUID -ne 0 ]] && echo -e "[${red}Error${plain}] This script must be run as root!" && exit 1

#Check system
check_sys(){
    local checkType=$1
    local value=$2

    release=''
    systemPackage=''

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

get_char(){
    SAVEDSTTY=`stty -g`
    stty -echo
    stty cbreak
    dd if=/dev/tty bs=1 count=1 2> /dev/null
    stty -raw
    stty echo
    stty $SAVEDSTTY
}

pre_install_docker_compose(){
    # Set ssrpanel_container_name
    if [ "${is_copy}" == "n" ];then
    echo "docker容器名字"
    read -p "(Default value: yyg ):" container_name
    [ -z "${container_name}" ] && container_name=yyg
    echo
    echo "---------------------------"
    echo "容器名 = ${container_name}"
    echo "---------------------------"
    echo
    fi
    echo "节点ID"
    read -p "(Default value: 0 ):" node_id
    [ -z "${node_id}" ] && node_id=0
    echo
    echo "---------------------------"
    echo "node_id = ${node_id}"
    echo "---------------------------"
    echo
}

config_xrayr_type_show(){
  for((i=1;i<=${#tmp_type[@]};i++))
  do
      echo "${i}.${tmp_type[${i}-1]}"
  done
}
config_xrayr_type(){
    echo "enter your choose:"
    read type_num
    [ -z "${type_num}" ] && type_num="1"
    for((j=1;j<=${#tmp_type[@]};j++))
    do
      if [ ${type_num} == "${j}" ];then
        return_name=${tmp_type[${j}-1]}
      fi
    done
}
config_xrayr(){
	  if [ "$is_copy" == "n" ];then
  	  curl -L ${github_url}/xrayr/docker-compose.yml > docker-compose.yml
  	  wget ${github_dw_url}/xrayr/config.tar.gz
      curl -L ${github_url}/xrayr/config_sample.yml > config_sample.yml
      tar -xzvf config.tar.gz
      sed -i "s|container_name:.*|container_name: ${container_name}|"  ./docker-compose.yml
      fi
      echo "configura config"
      echo "choose your type of panel (default SSpanel)"
      tmp_type=("${panel_list[@]}")
      config_xrayr_type_show
      config_xrayr_type
      panel_type="${return_name}"
      echo "choose your type of Node (default V2ray)"
      unset $tmp_type
      unset $return_name
      tmp_type=("${node_type_list[@]}")
      config_xrayr_type_show
      config_xrayr_type
      node_type="${return_name}"
      echo "enter your weburl:"
      echo
      read xray_weburl
      echo "enter your web token:"
      echo
      read xray_key
      sed -i "s|NodeID:.*|NodeID: ${sspanel_node_id}|"  ./config_sample.yml
      sed -i "s|ApiHost:.*|ApiHost: \"${xray_weburl}\"|" ./config_sample.yml
      sed -i "s|ApiKey:.*|ApiKey: \"${xray_key}\"|" ./config_sample.yml
      sed -i "s|PanelType.*|PanelType: ${panel_type}|" ./config_sample.yml
      sed -i "s|NodeType:.*|NodeType: ${node_type}|" ./config_sample.yml
      echo "open DNS for netflix?(y/n)"
      echo
      read dns_nf
      if [ ${dns_nf} == "y" ];then
      echo "enter your dns ip"
      read dns_ip
      sed -i "s|DnsConfigPath.*|DnsConfigPath: /etc/XrayR/dns.json|" ./config_sample.yml
      sed -i "s|EnableDNS.*|EnableDNS: true|" ./config_sample.yml
      sed -i "s|DNSType.*|DNSType: UseIP|" ./config_sample.yml
      sed -i "s|\"address\": \"1.1.2.2\"|\"address\": \"${dns_ip}\"|" ./config_sample.yml
      else
      sed -i "s|EnableDNS.*|EnableDNS: false|" ./config_sample.yml
      sed -i "s|DNSType.*|DNSType: AsIs|" ./config_sample.yml
      fi
      echo "use cert ?(y/n)"
      echo
      read cert_o
      if [ ${cert_o} == "y" ];then
      echo "choose your type of cert (default file)"
      unset $tmp_type
      unset $return_name
      tmp_type=("${cert_list[@]}")
      config_xrayr_type_show
      config_xrayr_type
      cert_type="${return_name}"
      echo "enter youer cert domin"
      read cert_domin
      echo "enter your cert file local if http pass here"
      read cert_file
      echo "enter your key file local if http pass here"
      read key_file
      sed -i "s|CertMode:.*|CertMode: ${cert_type}|" ./config_sample.yml
      sed -i "s|CertDomain.*|CertDomain: ${cert_domin}|" ./config_sample.yml
      sed -i "s|CertFile.*|CertFile: ${cert_file}|" ./config_sample.yml
      sed -i "s|KeyFile.*|KeyFile: ${key_file}|" ./config_sample.yml
      fi
}
config_xrayr_docker(){
is_copy="n"
	pre_install_docker_compose
    panel_list=(SSpanel V2board Proxypanel)
    node_type_list=(V2ray Shadowsocks Trojan)
    cert_list=(http file)
    echo "configura docker-compose.yml"
    mkdir -p yaoyue/xrayr/${container_name}
    cd yaoyue/xrayr/${container_name}
    while true
    do
    config_xrayr
    cat ./config_sample.yml |tee -a ./config/config.yml
    echo "coutinue to add node ?(y/n)"
    read eth
    [ -z "${eth}" ] && eth="n"
    if [ ${eth} == "n" ];then
      is_copy="n"
      break;
    else
      unset is_copy
      is_cpoy="y"
    fi
    pre_install_docker_compose
    done
}

install_check(){
    if check_sys packageManager yum || check_sys packageManager apt; then
        if centosversion 5; then
            return 1
        fi
        return 0
    else
        return 1
    fi
}

install_dependencies(){
    echo -e "[${green}Info${plain}] Setting TimeZone to Shanghai"
    ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
    date -s "$(curl -sI g.cn | grep Date | cut -d' ' -f3-6)Z"
    echo "install curl"
    ${systemPackage} install -y curl
}
bbr(){
	bash <(curl -L sh.xdmb.xyz/tcp.sh)
	sleep 5s
	get_char
}

#show last 100 line log

logs_v2ray(){
    compose_list=`docker ps |grep xrayr|awk -F " " '{print $NF}'`
    echo "Last 100 line logs"
    docker-compose logs --tail 100
}


check_ins(){
    if type $1 >/dev/null 2>&1 
    then
    ins_stats=1
    else
    ins_stats=0
    fi
}
docker_install_ba(){
    check_sys
    if [ ${systemPackage} == "yum" ]
    then
    yum install -y yum-utils device-mapper-persistent-data lvm2
    yum-config-manager --add-repo http://mirrors.aliyun.com/docker-ce/linux/centos/docker-ce.repo
    yum install docker-ce docker-ce-cli containerd.io
    elif [ ${release} == "debian" ];then
    apt-get update
    apt-get install apt-transport-https ca-certificates curl gnupg2 software-properties-common
    curl -fsSL https://mirrors.ustc.edu.cn/docker-ce/linux/debian/gpg | sudo apt-key add -
    add-apt-repository "deb [arch=amd64] https://mirrors.ustc.edu.cn/docker-ce/linux/debian $(lsb_release -cs) stable"
    apt-get update
    apt-get install docker-ce docker-ce-cli containerd.io
    else
    apt-get update
    apt-get install apt-transport-https ca-certificates curl gnupg-agent software-properties-common
    curl -fsSL https://mirrors.ustc.edu.cn/docker-ce/linux/ubuntu/gpg | sudo apt-key add -
    add-apt-repository "deb [arch=amd64] https://mirrors.ustc.edu.cn/docker-ce/linux/ubuntu/ $(lsb_release -cs) stable"
    apt-get update
    apt-get install docker-ce docker-ce-cli containerd.io
    fi
}

docker_compose_install(){
    curl -L "https://github.com/docker/compose/releases/download/1.25.3/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    chmod a+x /usr/local/bin/docker-compose
    rm -f `which dc`
    ln -s /usr/local/bin/docker-compose /usr/bin/dc
    systemctl start docker
    systemctl enable docker.service
}
docker_install(){
    check_sys
    check_ins curl
    if [ ${ins_stats} -eq 0 ]
    then
    ${systemPackage} install -y curl
    fi
    check_ins docker
    if [ ${ins_stats} -eq 0 ]
    then
    curl -fsSL https://get.docker.com | bash
    else
    check_ins docker-compose
    if [ ${ins_stats} -eq 0 ]
    then
    docker_compose_install
    fi
    fi
    check_ins docker
    if [ ${ins_stats} -eq 0 ]
    then
    docker_install_ba
    docker_compose_install
    else
    check_ins docker-compose
    if [ ${ins_stats} -eq 0 ]
    then
    docker_compose_install
    fi
    fi
}

Exit(){
    exit
}

init(){
    cd ${def_dir}
    docker_install
    config_xrayr_docker
    dc up -d
    if [ ${systemPackage} == "apt" ]
    then
    echo "0 4 * * * /usr/bin/docker restart ${container_name}" >> /var/spool/cron/crontabs/root
    else
    echo "0 4 * * * /usr/bin/docker restart ${container_name}" >> /var/spool/cron/root
    fi
}

yyver(){
    echo "The version: yaoyue 20220507A"
    echo "return after 5s"
    sleep 5s
}

# Initialization step
initial(){
    clear
    while true
    do
    echo "---------------------------"
    echo "welcome to 妖月脚本"
    echo "built by @xyhy919"
    echo "---------------------------"
    echo  "Which operation you'd select:"
    for ((i=1;i<=${#operation[@]};i++ )); do
        hint="${operation[$i-1]}"
        echo -e "${green}${i}${plain}) ${hint}"
    done
    read -p "Please enter a number (Default ${operation[0]}):" selected
    [ -z "${selected}" ] && selected="1"
    case "${selected}" in
        1|2|3|4)
        echo
        echo "You choose = ${operation[${selected}-1]}"
        echo
        ${operation[${selected}-1]}
        break
        ;;
        *)
        echo -e "[${red}Error${plain}] Please only enter a number [1-${#operation[@]}]"
        ;;
    esac
    done
}

install_dependencies
while true
do
initial
done
