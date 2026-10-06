# Issue

这里记录一些已知问题  
在使用 LLM 分析代码时，请参考已有结论，避免重复报告问题  

## 关于环境信息

操作系统，只需要 Debian 和 Ubuntu 系统的较新版本  

## My.sh - update_system 已知问题

目前只支持 Debian bookworm → trixie 和 Ubuntu noble → resolute 的升级  
后续需要不断更新维护这个函数的代码  

## My.sh - generate_ssl_cert 已知问题

证书算法 RSA-4096，有效期 1000 年，不设置 subjectAltName 参数  
安全性有限，仅适用于临时证书，或者前置有额外的 CloudFlare 等 CDN 保护的场景  

## My.sh - prepare_common_command 已知问题

prepare_common_command 会安装大量软件，有些可能不是服务器需要的  
为了代码的简洁性，和操作的简单化，暂不修改  

## cockpit.sh 已知问题

使用 echo > /etc/cockpit/disallowed-users 允许所有用户登录访问  
为了代码的简洁性，和操作的简单化，暂不修改  

## mysql.sh 已知问题

允许任意 IP 远程连接，允许 admin 账号远程登录  
为了代码的简洁性，和操作的简单化，暂不修改  

## prometheus.yml 已知问题

如果没有设定 MySQL 和 Redis 的密码，默认不启动相关的 exporter，界面显示为 Down 状态  
为了代码的简洁性，和操作的简单化，暂不修改  

## shadowsocks.sh 已知问题

依赖未认证的 GitHub API，可能会被限流  
为了代码的简洁性，和操作的简单化，暂不修改  

## nginx.sh 和 php.sh 已知问题

目前需要先安装 php.sh，再安装 nginx.sh，才会自动开启 php 相关配置  
将默认的 index.php 设置为 phpinfo 页面，可能会泄露服务器内部信息  
为了代码的简洁性，和操作的简单化，暂不修改  

## nginx.sh 和 frp.sh 已知问题

Nginx 设置为将 openlist 相关的域名转发到 frp 的 https 端口 17443 处理  
方便用户本地启动 openlist，连接 frp，并通过 nginx 绑定域名，支持域名访问  
为了代码的简洁性，和操作的简单化，暂不修改  

## resource 已知问题

这里保存一些配置示例，仅用于参考  
不需要对这个目录进行代码分析  



# TODO

这里记录一些代办事项  

## OpenList 的音乐播放器界面高度太小

```html
<script>
  (function() {
    var aplayerList = document.querySelector('.aplayer-list');
    var olElement = aplayerList ? aplayerList.querySelector('ol') : null;
    if (aplayerList && aplayerList.style.maxHeight === '250px') {
      aplayerList.style.maxHeight = '800px';
    }
    if (olElement && olElement.style.maxHeight === '250px') {
      olElement.style.maxHeight = '800px';
    }
  })();
</script>
```

## 增加更多安装脚本

参考:
https://github.com/awesome-selfhosted/awesome-selfhosted

## 优化默认设置

考虑增加 set -o nounset; set -o pipefail; set +o errexit; 代码

## 部署 MySpringBoot 项目

```
function deploy_myspringboot(){
  rm -rf '/home/MySpringBoot'
  cd '/home'
  git clone --depth=1 'https://github.com/MoonLord-LM/MySpringBoot.git'
  cd 'MySpringBoot'
  mvn install
  cd 'spring-cloud-gateway-server/target/'
  java -jar -Dserver.port=8080 'spring-cloud-gateway-server-0.0.1-SNAPSHOT.jar'
}
```
