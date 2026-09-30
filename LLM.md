# TODO

## 新增 root 密码重设函数

新增 root 密码重设函数，使用 256 bit 随机数

```shell
password=$(head -c 32 '/dev/urandom' | base64 -w 0)
```

## 对各种 WEB UI 指定 URL 的根路径

分配各自的相对路径，方便绑定到同一个域名上访问

    http://103.233.74.96:19090/Prometheus
    http://103.233.74.96:13000/Grafana
    http://103.233.74.96:17500/Frp
    https://103.233.74.96:19190/Cockpit

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
https://github.com/photoprism/photoprism
https://writefreely.org
