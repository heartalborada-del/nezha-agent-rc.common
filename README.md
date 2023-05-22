# nezha-agent-rc.common
适用于rc.common的nezha agent部署脚本

~~本项目源于我的一位朋友家OpenWrt经常炸系统，我又不想每次都重装Agen，于是有了本脚本~~
## How to use it
兼容官方部署脚本

例如
```bash
curl -L https://raw.githubusercontent.com/naiba/nezha/master/script/install.sh -o nezha.sh && chmod +x nezha.sh && sudo ./nezha.sh install_agent rpc port key --tls
```
只需要更改为
```bash
curl -L https://raw.githubusercontent.com/heartalborada-del/nezha-agent-rc.common/main/install.sh -o nezha.sh && chmod +x nezha.sh && sudo ./nezha.sh rpc port key --tls
```
即可安装
