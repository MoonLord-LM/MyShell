# TODO

## 新增 root 密码重设函数

新增 root 密码重设函数，使用 256 bit 随机数

```shell
password=$(head -c 32 '/dev/urandom' | base64 -w 0)
```

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
