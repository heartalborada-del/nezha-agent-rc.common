#!/bin/bash
os_arch=""
red='\033[0;31m'
green='\033[0;32m'
yellow='\033[0;33m'
plain='\033[0m'
command -v curl >/dev/null 2>&1 || { echo >&2 "This system is not supported: curl not found"; exit 1; }
## os arch
if [[ $(uname -m | grep 'x86_64') != "" ]]; then
    os_arch="amd64"
elif [[ $(uname -m | grep 'i386\|i686') != "" ]]; then
    os_arch="386"
elif [[ $(uname -m | grep 'aarch64\|armv8b\|armv8l') != "" ]]; then
    os_arch="arm64"
elif [[ $(uname -m | grep 'arm') != "" ]]; then
    os_arch="arm"
elif [[ $(uname -m | grep 's390x') != "" ]]; then
    os_arch="s390x"
elif [[ $(uname -m | grep 'riscv64') != "" ]]; then
    os_arch="riscv64"
fi
echo -e "Your system arch is ${os_arch}"
## args check
rpc=$1
port=$2
key=$3
if [[ -z "${rpc}" || -z "${port}" || -z "${key}" ]]; then
    echo -e "${red}All options cannot be empty${plain}"
    exit 0
fi
## China IP
if [[ -z "${CN}" ]]; then
     if [[ $(curl -m 10 -s https://ipapi.co/json | grep 'China') != "" ]]; then
        echo "According to the information provided by ipapi.co, the current IP may be in China"
        read -e -r -p "Is the installation done with a Chinese Mirror? [Y/n] " input
        case $input in
            [yY][eE][sS] | [yY])
                echo "Use Chinese Mirror"
                CN=true
                ;;
            [nN][oO] | [nN])
                echo "No Use Chinese Mirror"
                ;;
            *)
                echo "Use Chinese Mirror"
                CN=true
                ;; 
        esac
    fi
fi
if [[ -z "${CN}" ]]; then
    GITHUB_RAW_URL="raw.githubusercontent.com/naiba/nezha/master"
    GITHUB_URL="github.com"
else
    GITHUB_RAW_URL="cdn.jsdelivr.net/gh/naiba/nezha@master"
    GITHUB_URL="mirror.ghproxy.com/https://github.com"
fi
## get version
echo -e "Obtaining Agent version"
version=$(curl -m 10 -sL "https://api.github.com/repos/nezhahq/agent/releases/latest" | grep "tag_name" | head -n 1 | awk -F ":" '{print $2}' | sed 's/\"//g;s/,//g;s/ //g')
if [ ! -n "$version" ]; then
    version=$(curl -m 10 -sL "https://fastly.jsdelivr.net/gh/nezhahq/agent/" | grep "option\.value" | awk -F "'" '{print $2}' | sed 's/nezhahq\/agent@/v/g')
fi
if [ ! -n "$version" ]; then
    version=$(curl -m 10 -sL "https://gcore.jsdelivr.net/gh/nezhahq/agent/" | grep "option\.value" | awk -F "'" '{print $2}' | sed 's/nezhahq\/agent@/v/g')
fi
if [ ! -n "$version" ]; then
    echo -e "Fail to obtaine agent version, please check if the network can link https://api.github.com/repos/nezhahq/agent/releases/latest"
    exit 0
else
    echo -e "The current latest version is: ${version}"
fi
## agent installation
read -e -r -p "Would you want to cotinue? [Y/n] " input
case $input in
    [yY][eE][sS] | [yY])
        echo "Continue the installation."
        ;;
    [nN][oO] | [nN])
        echo "Exit the installation."
        exit 0
        ;;
    *)
        echo "Continue the installation."
        ;;
esac
## create path
agent_path="/etc/nezha/"
mkdir -p $agent_path
chmod 755 -R $agent_path
cd $agent_path
echo -e "Downloading agent at https://${GITHUB_URL}/nezhahq/agent/releases/download/${version}/nezha-agent_linux_${os_arch}.zip"
curl --retry 5 -o nezha-agent_linux_${os_arch}.zip -L https://${GITHUB_URL}/nezhahq/agent/releases/download/${version}/nezha-agent_linux_${os_arch}.zip
if [[ $? != 0 ]]; then
    echo -e "${red}Fail to download agent, please check if the network can link ${GITHUB_URL}${plain}"
    exit 0
fi
unzip -qo nezha-agent_linux_${os_arch}.zip &&
rm -rf nezha-agent_linux_${os_arch}.zip README.md &&
chmod +x nezha-agent
other_opt=""
for i in `seq 4 $#`
do 
    other_opt="${other_opt} ${!i}"
done
##output
rm -rf /etc/init.d/nezha-service
touch /etc/init.d/nezha-service
serive="#!/bin/sh /etc/rc.common\n
\n
START=99\n
USE_PROCD=1\n
\n
start_service() {\n
 procd_open_instance\n
 procd_set_param command ${agent_path}nezha-agent -s $rpc:$port -p $key$other_opt\n
 procd_set_param respawn\n
 procd_close_instance\n
}\n
\n
stop_service() {\n
    killall nezha-agent\n
}\n
\n
restart() {\n
 stop\n
 sleep 2\n
 start\n
}\n" 
echo -e ${serive} > /etc/init.d/nezha-service
chmod +x /etc/init.d/nezha-service
/etc/init.d/nezha-service start
read -e -r -p "Do you want to set it to start with the system? [Y/n] " input
case $input in
    [yY][eE][sS] | [yY])
        /etc/init.d/nezha-service enable
        ;;
    [nN][oO] | [nN])
        echo "You can input \"/etc/init.d/nezha-service enable\" to start with system"
        ;;
    *)
        /etc/init.d/nezha-service enable
        ;;
esac
echo "Done"
