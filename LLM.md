# Issue

这里记录一些已知问题  
在使用 LLM 分析代码时，请参考已有结论，避免重复报告问题  

## My.sh - generate_ssl_cert 已知问题

证书算法 RSA-4096，有效期 1000 年，不设置 subjectAltName 参数  
安全性有限，仅用于临时证书，或前端额外有 CloudFlare 等 CDN 保护的场景  

## My.sh - prepare_common_command 已知问题

会安装大量软件，有些可能不是服务器需要的  
但是为了代码的简洁性，和操作的简单，仍然按照现有的方案  

## My.sh - update_system 已知问题

目前只支持 Debian bookworm → trixie 和 Ubuntu noble → resolute 的升级  
后续需要不断更新维护这个函数的代码  

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

参考：
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
