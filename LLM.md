# TODO

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

# 优化默认设置

考虑增加 set -o nounset; set -o pipefail; set +o errexit; 代码

# 部署 MySpringBoot 项目

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
