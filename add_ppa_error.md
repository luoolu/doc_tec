## ubuntu无法添加PPA的解决办法

### 1.CA证书损坏
###  重装一遍CA证书
sudo apt-get install --reinstall ca-certificates

### 3. 没有绕过代理
###  绕过代理，加一个"-E"
sudo -E add-apt-repository --update ppa:ubuntu-toolchain-r/test

