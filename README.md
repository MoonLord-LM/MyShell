
# MyShell
A function library for the Linux Shell.  

## [简介]
Linux Shell 常用脚本函数收集整理  

## [说明]
- 字符编码：UFT-8  
- 测试环境：阿里云 CentOS 7.5 x64  

## [使用]
    yum install 'wget' -y && mkdir -m 777 -p '/home/install' && cd '/home/install' \  
    wget 'https://raw.githubusercontent.com/MoonLord-LM/MyShell/master/install/My.sh' -O 'My.sh' \  
    source 'My.sh' && my_init  
      
      
      

## [笔记]
01. 报错 Permission denied 是因为权限不足，需要使用 chmod 命令增加权限  
02. 报错 /bin/bash^M: bad interpreter: No such file or directory 是因为使用了 \r\n 的换行符，需要改成 \n 换行  
03. 从命令末尾的 “<<EOF” 到后续某一行开头的 “EOF”，这中间的文本，将被作为这条命令的一次标准输入，进行执行  
04. 通过 ``[ $? -eq 0 ] && echo "OK" || echo "Fail"`` 来判断上一条命令是否执行成功  
05. 使用 echo 输出多行字符串的变量时，需要加引号，否则会变成一行，例如 ``tmp=`ls -la` && echo $tmp && echo "$tmp"``  
06. 错误修改 /etc/fstab 配置文件后重启，可能导致文件系统只读，无法恢复配置，则需要 ``mount -o remount rw /``  
07. 远程登录进入 mysql 控制台时，要注意输入的 SQL 语句中的 Shell 变量（如 $tmp），不会被替换为变量的值  
08. 使用 ``setsid ping -c 5 'www.moonlord.cn'`` 或 ``( ping -c 5 'www.moonlord.cn' &)`` 异步执行命令  
09. 修改 root 用户密码：使用 ``passwd`` 命令，修改 SSH 远程登录端口号：修改 /etc/ssh/sshd_config  的 Port 值  
