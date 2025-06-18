1, "gksu-gtk-warning-cannot-open-display-0"?
	  sudo vim .bashrc
	Add the following line at the end.
	  export XAUTHORITY=$HOME/.Xauthority
	  source .bashrc

2,

## 解决E: Sub-process /usr/bin/dpkg returned an error code (1)问题

一开始参照这个链接，但是没有解决问题
https://blog.csdn.net/u013832707/article/details/113104006

然后使用这个，解决了
cd /var/lib/dpkg/
sudo mv info/ info_bak # 现将info文件夹更名
sudo mkdir info # 再新建一个新的info文件夹
sudo apt-get update # 更新
sudo apt-get -f install # 修复
sudo mv info/* info_bak/ # 执行完上一步操作后会在新的info文件夹下生成一些文件，现将这些文件全部移到info_bak文件夹下
sudo rm -rf info # 把自己新建的info文件夹删掉
sudo mv info_bak info # 把以前的info文件夹重新改回名

## 
