## GitHub拉取代码慢解决方案

1.使用GitHub的镜像网站
现在能用的只剩这个了，下面的不用看了
https://github.91chi.fun/https://github.com

fastgit.org
https://doc.fastgit.org/

cnpmjs.org
https://github.com.cnpmjs.org/

gitclone
https://gitclone.com/

设置git config（设置的是用户配置文件：~/.gitconfig）：

git config --global http.postbuffer 1048576000
git config --global http.sslVerify false
git config --global http.lowSpeedLimit 0
git config --global http.lowSpeedTime 999999

2. 修改配置文件

直接修改~/.gitconfig文件

[url "https://hub.fastgit.org/"]
 insteadOf = https://github.com/

git config --global url."https://github.91chi.fun/https://github.com".insteadOf https://github.com








