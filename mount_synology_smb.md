(base) luolu@falconcore:~$ cd /home/ \
(base) luolu@falconcore:/home$ sudo mkdir -p /mnt/synology_smb \
(base) luolu@falconcore:/home$ sudo mount -t cifs //10.122.5.33/FalconCoreData /mnt/synology_smb -o username=sadmin,password=Loolo.HD6500,uid=$(id -u),gid=(id -g) \
bash: syntax error near unexpected token `(' \
(base) luolu@falconcore:/home$ sudo mount -t cifs //10.122.5.33/FalconCoreData /mnt/synology_smb -o username=sadmin,password=Loolo.HD6500,uid=$(id -u),gid=$(id -g) \
(base) luolu@falconcore:/home$ sudo vim /etc/fstab \
(base) luolu@falconcore:/home$ sudo vim ~/.credentials \
(base) luolu@falconcore:/home$ chmod 600 ~/.credentials  \
chmod: changing permissions of '/home/luolu/.credentials': Operation not permitted \
(base) luolu@falconcore:/home$ sudo chmod 600 ~/.credentials  \
(base) luolu@falconcore:/home$ sudo mount -a \
"""//10.122.5.33/FalconCoreData /mnt/synology_smb cifs credentials=/home/luolu/.smbcredentials,uid=1000,gid=1000,iocharset=utf8 0 0
""" \  """username=sadmin \
password=Loolo.HD6500 \
"""
![clipbord_1748418793705](https://github.com/user-attachments/assets/74e998de-584d-4d98-86ee-5cc615b4bcdb)

![clipbord_1748418976700](https://github.com/user-attachments/assets/0bcc7a29-7b2a-4e43-829a-faed6f13dd2c)

 ![image](https://github.com/user-attachments/assets/f27e6cac-3d0f-497b-9593-f3da84d2dfac)
***************************************************************************************************
在 CIFS／SMB 协议里，服务器只会“导出”它配置好的 **share**（也就是你挂载时要指定的 `//server/share`），并不存在一个类似 Linux 文件系统根目录下能直接列出所有 share 的“超级 share”。要想访问 `//10.122.5.33/` 下的全部共享，你需要做以下两种方案之一：

---

## 1. 手动列出并逐个挂载

1. **列出服务器上可用的所有 share**

   ```bash
   smbclient -L //10.122.5.33 -U sadmin
   ```

   输入密码后，就能看到类似：

   ```
   Sharename       Type      Comment
   ---------       ----      -------
   FalconCoreData  Disk      Falcon core data share
   Public          Disk      Public share
   Backup          Disk      Backup files
   IPC$            IPC       IPC Service (Samba 4.x)
   ```
2. **为每个 share 创建一个挂载点，并挂载**

   ```bash
   sudo mkdir -p /mnt/smb/FalconCoreData
   sudo mount -t cifs //10.122.5.33/FalconCoreData /mnt/smb/FalconCoreData \
     -o username=sadmin,password=Loolo.HD6500,uid=$(id -u),gid=$(id -g)

   sudo mkdir -p /mnt/smb/Public
   sudo mount -t cifs //10.122.5.33/Public /mnt/smb/Public \
     -o username=sadmin,password=Loolo.HD6500,uid=$(id -u),gid=$(id -g)

   …（其他 share 同理）
   ```
3. **访问**
   这样你就可以通过 `/mnt/smb/<Sharename>` 来同时读写各个共享了。

---

## 2. 用 autofs 动态通配挂载（更方便批量管理）

如果你不想每次都手动为新加的 share 建挂载点，可以安装并配置 `autofs`，让它在你访问 `/mnt/smb/<Sharename>` 时自动挂载／卸载：

1. **安装 autofs**

   ```bash
   sudo apt update
   sudo apt install autofs cifs-utils
   ```
2. **编辑主配置** `/etc/auto.master`，添加一行：

   ```
   /mnt/smb  /etc/auto.smb  --timeout=60
   ```
3. **创建映射文件** `/etc/auto.smb`，内容如下：

   ```
   *   -fstype=cifs,username=sadmin,password=Loolo.HD6500,uid=1000,gid=1000    ://10.122.5.33/&
   ```

   * `*` 表示任意子目录名都会映射到同名 share
   * 最后面的 `&` 会被替换成前面的通配符（也就是 `Public`、`FalconCoreData` 等）
4. **重启 autofs**

   ```bash
   sudo systemctl restart autofs
   ```
5. **使用**
   现在你只要访问例如 `/mnt/smb/Public`，autofs 会自动把 `//10.122.5.33/Public` 挂载到它上面；访问完会在 60 秒内自动卸载。

---

### 为什么不能直接“挂到根目录” `/`

* Linux 下的“根目录” `/` 已经被本地文件系统占用，直接 `mount //10.122.5.33/ /` 会把本地所有文件都隐藏掉，而且 SMB 协议也不支持不指定 share 名的“根挂载”。
* 如果真的需要把某个 share 挂到 `/`，必须确保 `/` 下面原有内容都在另一个地方，并且在系统启动时用 initramfs 先挂载；这通常只用于制作网络启动系统，不适合日常使用。

---

**总结**

* **最直接**：用 `smbclient -L` 列出所有 share，然后按需用 `mount -t cifs //server/share /mnt/...` 一一挂载。
* **最优雅**：用 `autofs` 配合通配符，访问时自动挂载，管理多 share 一劳永逸。
