# Linux之vnc启动及异常处理

## Can't find file /home/user/.vnc/dell-8440:7.pid
1）启动桌面1的服务
$ vncserver :port

2) 杀掉已经启动的VNC服务进程
$ vncserver -kill :port

3) 找到上面杀不死的进程
$ ps -ef | grep -i vnc | grep -v grep

4）手工杀掉已经启动的VNC服务进程
$ kill -9 pid

5）确认进程已经杀掉
$ ps -ef | grep -i vnc | grep -v grep

## 再次启动桌面1的VNC服务，这里可以看到报错

$ vncserver :1

Warning: testdb:1 is taken because of /tmp/.X1-lock
Remove this file if there is no X server testdb:1
A VNC server is already running as :1

6）按照错误提示的内容，需要删除/tmp/.X1-lock文件

$ rm -f /tmp/.X1-lock

7) 启动尝试，仍然报错

$ vncserver :1

Warning: testdb:1 is taken because of /tmp/.X11-unix/X1
Remove this file if there is no X server testdb:1
A VNC server is already running as :1

8) 同样，按照提示的错误，进一步删除/tmp/.X11-unix/X1文件
$ rm -f /tmp/.X11-unix/X1

9) 再次启动，成功
10) $ vncserver :1






