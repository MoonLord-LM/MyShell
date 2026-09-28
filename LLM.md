# TODO

## 新增配置文件安全修改函数

将配置文件的目录创建、文件备份和内容修改整合为 My.sh 里的一个函数
同时，当文件内容无变化的时候，不进行备份和覆盖

```shell
mkdir -p $(dirname "${conf_file}")
backup_file "${conf_file}"
config_conf > "${conf_file}"
```
## 新增 root 密码重设函数

新增 root 密码重设函数，使用 256 bit 随机数

```shell
password=$(head -c 32 '/dev/urandom' | base64 -w 0)
```

## 系统更新后，源没有跟随更新的问题

    Hit:1 http://security.debian.org/debian-security trixie-security InRelease
    Hit:2 http://deb.debian.org/debian trixie InRelease
    Hit:3 http://deb.debian.org/debian trixie-updates InRelease
    Hit:4 https://packages.sury.org/php trixie InRelease
    Hit:5 https://download.docker.com/linux/debian bookworm InRelease
    Hit:6 https://packages.redis.io/deb bookworm InRelease
    Hit:7 http://repo.mysql.com/apt/debian bookworm InRelease

## 考虑增加一个文件管理的 WEB UI

    FileBrowser‑Quantum
    OpenList

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
