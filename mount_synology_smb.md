明确：你要 **开机自动挂载 Synology 上三个存储池（假设它们在 DSM 里已经以共享目录的形式暴露，比如 `volume1`/`volume2`/`volume3` 或它们底下的共享文件夹）**，并且一次性把当前所有可见的 share 挂上。下面是可立即执行、稳健的全流程（Ubuntu 24 Server）。

---

## 1. Synology 端先做准备（在 DSM 上确认）

1. 在 DSM 控制台里 **开启 SMB/CIFS 服务**（Control Panel → File Services → SMB）
2. 确保你想挂载的目录被设置为 **共享文件夹**（Share）。

   * 如果你想挂载整个 volume，比如 `volume1`，就要在 DSM 里将 `volume1` 设为一个共享（或在“Shared Folder”里创建一个指向 volume1 根的共享）。
3. 确保账号 `sadmin` 有对这些共享的 **读写权限**。

---

## 2. 在 Ubuntu 上安装依赖

```bash
sudo apt update
sudo apt install -y cifs-utils smbclient
```

---

## 3. 测试列出当前所有可挂载的共享（确认网络与认证）

```bash
# 不交互地列出 share（如果提示要密码，用 -U sadmin%Loolo.HD6500 也可以）
smbclient -L 10.122.5.33 -U sadmin%Loolo.HD6500
```

你应该能看到类似 `volume1`, `volume2`, `volume3` 或它们下面的共享文件夹名称（如 `Weights`、`FalconCoreData` 等）。记下你要挂的那些 share 名称，如果是 volume 本身就用它们。

---

## 4. 创建凭证文件（避免在命令/配置里明文）

```bash
sudo tee /etc/samba/credentials_synology > /dev/null <<EOF
username=sadmin
password=Loolo.HD6500
EOF

sudo chmod 600 /etc/samba/credentials_synology
```

---

## 5. 写一个“一键自动枚举当前所有 share 并挂载”的脚本

创建脚本 `/usr/local/bin/synology-auto-mount.sh`：

```bash
sudo tee /usr/local/bin/synology-auto-mount.sh > /dev/null <<'EOF'
#!/bin/bash

NAS=10.122.5.33
CRED=/etc/samba/credentials_synology
BASE=/home/data-vg0/mnt/synology_all

# 获取共享列表（去掉 IPC$ 之类的系统项）
shares=$(smbclient -L "${NAS}" -N -U sadmin 2>/dev/null | awk '/^  [^ ]/ {print $1}' | grep -vE '^(IPC\$)$')

# 确保基础目录存在
mkdir -p "${BASE}"

for share in $shares; do
  mountpoint="${BASE}/${share}"
  unit_name="mnt-data-vg0-mnt-synology_all-${share}.mount"  # systemd 单元名需要把路径 / 替换成 -
  # 创建本地挂载点
  sudo mkdir -p "${mountpoint}"

  # 构造 systemd .mount 单元路径（注意转义规则，路径 /home/data-vg0/mnt/synology_all/${share} 对应 unit 名）
  # systemd 的命名是把路径去掉前导 /，把 / 替换为 -，再加 .mount
  # 例如： /home/data-vg0/mnt/synology_all/Weights -> home-data-vg0-mnt-synology_all-Weights.mount
  unit_name=$(echo "${mountpoint}" | sed 's/^\///; s/\//-/g').mount
  unit_path="/etc/systemd/system/${unit_name}"

  # 生成 .mount unit
  cat <<UNIT | sudo tee "${unit_path}" > /dev/null
[Unit]
Description=Mount //${NAS}/${share}
After=network-online.target
Wants=network-online.target

[Mount]
What=//${NAS}/${share}
Where=${mountpoint}
Type=cifs
Options=credentials=${CRED},_netdev,iocharset=utf8,file_mode=0777,dir_mode=0777,uid=1000,gid=1000,vers=3.2

[Install]
WantedBy=multi-user.target
UNIT

  sudo systemctl daemon-reload
  sudo systemctl enable --now "${unit_name}"
done
EOF

sudo chmod +x /usr/local/bin/synology-auto-mount.sh
```

> 注意：如果你的本地用户不是 UID 1000/GID 1000，用 `id` 查出你的 uid/gid，并替换上面 unit 文件里 `uid=... ,gid=...`。

---

## 6. 创建开机运行该脚本的 systemd oneshot service

写 unit 文件 `/etc/systemd/system/synology-auto-mount.service`：

```bash
sudo tee /etc/systemd/system/synology-auto-mount.service > /dev/null <<'EOF'
[Unit]
Description=Auto create and mount all Synology shares
After=network-online.target
Wants=network-online.target

[Service]
Type=oneshot
ExecStart=/usr/local/bin/synology-auto-mount.sh
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOF
```

启用并立即执行：

```bash
sudo systemctl daemon-reload
sudo systemctl enable --now synology-auto-mount.service
```

---

## 7. 验证挂载是否成功

```bash
# 看所有挂载点
mount | grep synology_all

# 或单个状态
systemctl status $(echo /home/data-vg0/mnt/synology_all/Weights | sed 's/^\///; s/\//-/g').mount

# 列出目录内容（触发访问后应该已经挂上）
ls /home/data-vg0/mnt/synology_all
```

---

## 8. （可选）稳固：如果你只固定想挂载 volume1/2/3 这三个 share，可以跳过动态脚本，直接用 fstab 挂载

示例在 `/etc/fstab` 加三行（假设共享名就是 volume1、volume2、volume3）：

```fstab
//10.122.5.33/volume1  /home/data-vg0/mnt/synology_all/volume1  cifs  credentials=/etc/samba/credentials_synology,_netdev,iocharset=utf8,file_mode=0777,dir_mode=0777,uid=1000,gid=1000,vers=3.2  0 0
//10.122.5.33/volume2  /home/data-vg0/mnt/synology_all/volume2  cifs  credentials=/etc/samba/credentials_synology,_netdev,iocharset=utf8,file_mode=0777,dir_mode=0777,uid=1000,gid=1000,vers=3.2  0 0
//10.122.5.33/volume3  /home/data-vg0/mnt/synology_all/volume3  cifs  credentials=/etc/samba/credentials_synology,_netdev,iocharset=utf8,file_mode=0777,dir_mode=0777,uid=1000,gid=1000,vers=3.2  0 0
```

然后：

```bash
sudo mkdir -p /home/data-vg0/mnt/synology_all/volume1
sudo mkdir -p /home/data-vg0/mnt/synology_all/volume2
sudo mkdir -p /home/data-vg0/mnt/synology_all/mnt/synology_all/volume3  # 注意路径打好
sudo mount -a
```

---

## 9. 故障排查命令

```bash
# 查看 .service / .mount 单元日志
journalctl -u synology-auto-mount.service --since "5 minutes ago"
journalctl -u home-data-vg0-mnt-synology_all-Weights.mount

# 查看是否网络已就绪（影响挂载顺序）
systemctl status network-online.target

# 如果挂载失败，可尝试更改 SMB 协议版本，如 vers=3.0 或 vers=2.1
```

---

## 10. 之后重启测试

```bash
sudo reboot
# 重启后检查
mount | grep synology_all
ls /home/data-vg0/mnt/synology_all
```

---

如果你把实际的共享列表（`smbclient -L 10.122.5.33 -U sadmin%Loolo.HD6500` 输出）贴我，我可以直接给你生成对应的 fstab 片段和当前的 .mount unit 名称替换你的 UID/GID 并一键脚本化。

********************************************************************************************************************************
#### view mount
$ ls /home/data-vg0/mnt/synology_all/Weights
$ ls /home/data-vg0/mnt/synology_all/FalconCoreData

下面示例用 Autofs 做一个通配挂载，把 NAS 上所有共享（包括三大存储池下的所有 share）按需挂载到同一个父目录下：

---

## 1. 准备工作

* 确保已经安装了 `autofs` 和 `cifs-utils`，且已经有一个凭据文件 `/etc/samba/credentials_sadmin`，内容如下并且权限是 600：

  ```ini
  username=sadmin
  password=Loolo.HD6500
  ```

---

## 2. 创建挂载父目录

```bash
sudo mkdir -p /home/data-vg0/mnt/synology_all
```

---

## 3. 配置 Autofs 的映射（间接映射）

新建映射文件 `/etc/auto.synology`，内容如下：

```text
# 通配符 *：目录名即 share 名称；&
# 最后的 & 会自动被替换为目录名本身
*  -fstype=cifs,credentials=/etc/samba/credentials_sadmin,uid=0,gid=0,file_mode=0777,dir_mode=0777,vers=3.1.1,sec=ntlmssp,_netdev  ://10.122.5.33/&
```

* `*`：匹配任何子目录（即所有 share 名称）
* `://10.122.5.33/&`：`&` 会变成访问时的子目录名（share 名），相当于 `//10.122.5.33/ShareName`

---

## 4. 编辑 Autofs 主配置

向 `/etc/auto.master` 追加一行，告诉 Autofs 在哪个父目录下应用上面的映射：

```text
/home/data-vg0/mnt/synology_all  /etc/auto.synology  --timeout=60
```

* 访问 `/home/data-vg0/mnt/synology_all/SomeShare` 时，就会自动挂载 `//10.122.5.33/SomeShare`
* `--timeout=60` 表示 60 秒无访问后自动卸载

---

## 5. 重启 autofs

```bash
sudo systemctl restart autofs
```

---

## 6. 测试

1. 列出 NAS 上所有 share 名称（确认无误）：

   ```bash
   smbclient -L //10.122.5.33 -U sadmin
   ```
2. 访问挂载点下的某个子目录触发挂载：

   ```bash
   ls /home/data-vg0/mnt/synology_all/FalconCoreData
   ```
3. 查看已挂载：

   ```bash
   mount | grep synology_all
   ```

---

这样，你只要在 `/home/data-vg0/mnt/synology_all/任意ShareName` 下访问，就会动态去挂载对应的 NAS 共享，无需手动在 fstab 里写死每一个 share。

****************************************************************************************************************
下面给出在 Ubuntu 24 上改用 Autofs 自动挂载 Synology NAS 的详细步骤，以便你在访问挂载点时才触发挂载。

假设你要把 `FalconCoreData` 这个 share 挂载到 `/home/data-vg0/mnt/synology_smb`。

---

## 1. 安装 autofs

```bash
sudo apt update
sudo apt install -y autofs cifs-utils
```

## 2. 注释掉 `/etc/fstab` 中相关的 CIFS 条目

为了避免 Autofs 和 fstab 冲突，编辑 `/etc/fstab`，把之前添加的 NAS 挂载行前面加 `#` 注释掉，然后保存。

```bash
sudo sed -i 's@^//10.122.5.33/@#//10.122.5.33/@' /etc/fstab
```

## 3. （如未做）准备凭据文件

如果你之前已创建过 `/etc/samba/credentials_sadmin` 并 `chmod 600`，可跳过此步，否则：

```bash
sudo tee /etc/samba/credentials_sadmin > /dev/null <<EOF
username=sadmin
password=Loolo.HD6500
EOF
sudo chmod 600 /etc/samba/credentials_sadmin
```

## 4. 准备 Autofs 的映射文件

我们用 **直接映射**（direct map），把具体的绝对路径挂载到指定 CIFS 资源。

新建 `/etc/auto.synology` 并写入：

```bash
sudo tee /etc/auto.synology > /dev/null <<'EOF'
/home/data-vg0/mnt/synology_smb  -fstype=cifs,credentials=/etc/samba/credentials_sadmin,uid=0,gid=0,file_mode=0777,dir_mode=0777,vers=3.1.1,sec=ntlmssp,_netdev  ://10.122.5.33/FalconCoreData
EOF
```

* 左侧是要挂载的**完整路径**
* `-fstype=cifs,…` 为挂载选项，与你用 fstab 时基本一致
* 最后 `://10.122.5.33/FalconCoreData` 是目标分享

## 5. 告诉 Autofs 加载这个映射

编辑 `/etc/auto.master`，在末尾追加一行：

```bash
sudo tee -a /etc/auto.master > /dev/null <<EOF
/-    /etc/auto.synology    --timeout=60
EOF
```

* `/-` 表示启用 **直接映射**
* `--timeout=60` 表示空闲 60 秒后自动卸载（按需调整）

## 6. 重启 Autofs 服务

```bash
sudo systemctl restart autofs
```

## 7. 测试挂载

首次访问挂载点才会触发挂载：

```bash
# 目录本身可先创建一下，autofs 也会懒加载，但提前建好可以防止权限问题
sudo mkdir -p /home/data-vg0/mnt/synology_smb

# 访问试试
ls /home/data-vg0/mnt/synology_smb
```

如果配置正确，你会立即看到 NAS 上 `FalconCoreData` 里的文件列表。
此后，只要访问该目录就会自动 mount，空闲超过 60 秒则自动 umount。

*******************************************************************************************************************************
下面给出在 Ubuntu 24 上通过 CIFS（SMB）自动挂载 Synology NAS 的完整步骤与命令。按需将 `<SHARE>` 替换为你在 DSM 中创建的共享文件夹名称。

---

### 1. 安装必要组件

```bash
sudo apt update
sudo apt install -y cifs-utils smbclient
```

* `cifs-utils`：提供挂载 CIFS/SMB 的工具
* `smbclient`：用于列出 NAS 上的共享，确认 `<SHARE>` 名称

---

### 2. （可选）列出可用共享

```bash
smbclient -L //10.122.5.33 -U sadmin
```

* 回车后输入密码 `Loolo.HD6500`
* 输出里就能看到类似 `Sharename       Type   Comment`，确认要挂载的 `<SHARE>` 名称

---

### 3. 创建凭据文件

出于安全，不建议在 `/etc/fstab` 里明文写用户名／密码，改用凭据文件：

```bash
sudo tee /etc/samba/credentials_sadmin > /dev/null <<EOF
username=sadmin
password=Loolo.HD6500
# domain=WORKGROUP         # 如有 Windows 域可取消注释并填写
EOF

sudo chmod 600 /etc/samba/credentials_sadmin
```

---

### 4. 创建挂载点

```bash
sudo mkdir -p /mnt/synology
```

你可以根据喜好把挂载点改为其它路径，比如 `/media/nas`。

---

### 5. 配置 `/etc/fstab` 实现开机自动挂载

用你熟悉的编辑器打开：

```bash
sudo nano /etc/fstab
```

在末尾追加一行：

```fstab
//10.122.5.33/<SHARE>  /mnt/synology  cifs  credentials=/etc/samba/credentials_sadmin,uid=0,gid=0,file_mode=0777,dir_mode=0777,vers=3.0,sec=ntlmssp,_netdev  0  0
```

* `credentials=…`：指向上步创建的凭据文件
* `uid=0,gid=0`：以 root 身份挂载，管理员权限
* `file_mode=0777,dir_mode=0777`：文件/目录允许所有用户读写执行
* `vers=3.0`：指定 SMB 协议版本，可根据 NAS 设置调整（也可用 `vers=2.1`、`vers=1.0` 或 `vers=auto`）
* `sec=ntlmssp`：认证方式，Synology 默认支持 NTLMv2
* `_netdev`：开机挂载时等网络启动后再挂载

保存并退出。

---

### 6. 测试挂载

```bash
sudo mount -a
df -h | grep synology
```

* 如果输出中出现 `/mnt/synology` 且不报错，说明挂载成功
* 进入查看：

  ```bash
  ls -l /mnt/synology
  ```

---

### 7. 重启验证

重启机器，确认开机后挂载依然正常：

```bash
sudo reboot
# 重启后
df -h | grep synology
```

---

至此，你的 Ubuntu 24 便会在每次开机时自动，将 Synology NAS（10.122.5.33）的 `<SHARE>` 挂载到 `/mnt/synology`，管理员（root）可直接浏览、读取、写入所有文件。


********************************************************************************************************
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
**************************************************************************************************************
下面给出在 Ubuntu 上一次性挂载 Synology NAS 上三个存储池对应的「共享文件夹」的完整步骤，假设你的 NAS IP 是 `10.122.5.34`，用户名是 `sadmin`，密码是 `YourPassword`；共享名称分别对应：

* `/volume1/FalconCoreData` → 共享名 `FalconCoreData`
* `/volume2/FalconCore Datasets` → 共享名 `FalconCore Datasets`
* `/volume3/FalconCore PPT` → 共享名 `FalconCore PPT`

如果实际共享名有差异，请以 DSM “控制面板 → 共享文件夹” 中列出的名称为准。

---

## 一、在 Ubuntu 上预备工作

1. **安装 CIFS 工具**

   ```bash
   sudo apt update
   sudo apt install -y cifs-utils
   ```

2. **创建三个本地挂载点**

   ```bash
   sudo mkdir -p /mnt/volume1_FalconCoreData
   sudo mkdir -p /mnt/volume2_FalconCoreDatasets
   sudo mkdir -p /mnt/volume3_FalconCorePPT
   ```

3. **（可选）为了安全存放密码，创建凭证文件**

   ```bash
   sudo tee /root/.smbcredentials <<-EOF
   username=sadmin
   password=YourPassword
   domain=
   EOF
   sudo chmod 600 /root/.smbcredentials
   ```

---

## 二、临时手动挂载（验证用）

执行下面三条命令，确认能一次性挂载成功：

```bash
# 挂载 volume1 下的 FalconCoreData
sudo mount -t cifs //10.122.5.34/FalconCoreData \
  /mnt/volume1_FalconCoreData \
  -o credentials=/root/.smbcredentials,uid=$(id -u),gid=$(id -g),_netdev,vers=3.0

# 挂载 volume2 下的 FalconCore Datasets （路径有空格，用双引号包裹）
sudo mount -t cifs "//10.122.5.34/FalconCore Datasets" \
  /mnt/volume2_FalconCoreDatasets \
  -o credentials=/root/.smbcredentials,uid=$(id -u),gid=$(id -g),_netdev,vers=3.0

# 挂载 volume3 下的 FalconCore PPT
sudo mount -t cifs "//10.122.5.34/FalconCore PPT" \
  /mnt/volume3_FalconCorePPT \
  -o credentials=/root/.smbcredentials,uid=$(id -u),gid=$(id -g),_netdev,vers=3.0
```

**验证**：

```bash
ls /mnt/volume1_FalconCoreData
ls /mnt/volume2_FalconCoreDatasets
ls /mnt/volume3_FalconCorePPT
```

看到对应目录内容即挂载成功。

---

## 三、写入 `/etc/fstab` 实现开机自动挂载

1. 编辑 fstab：

   ```bash
   sudo nano /etc/fstab
   ```

2. 在文件末尾追加（注意对带空格的共享名，用 `\040` 转义）：

   ```
   //10.122.5.34/FalconCoreData      /mnt/volume1_FalconCoreData      cifs credentials=/root/.smbcredentials,uid=1000,gid=1000,_netdev,vers=3.0  0 0
   //10.122.5.34/FalconCore\040Datasets  /mnt/volume2_FalconCoreDatasets  cifs credentials=/root/.smbcredentials,uid=1000,gid=1000,_netdev,vers=3.0  0 0
   //10.122.5.34/FalconCore\040PPT       /mnt/volume3_FalconCorePPT       cifs credentials=/root/.smbcredentials,uid=1000,gid=1000,_netdev,vers=3.0  0 0
   ```

   * `uid=1000,gid=1000` 按你自己用户的 `id` 调整
   * `vers=3.0` 可根据 NAS 设置改为 `2.1`、`2.0`

3. 应用挂载：

   ```bash
   sudo mount -a
   ```

   再次用 `ls /mnt/...` 验证。

---

## 四、常见问题排查

* **挂载失败报 “Permission denied”**：

  * 检查 `sadmin` 在 DSM 里对该共享是否有读写权限。
  * 确认凭证文件格式和权限（`chmod 600`）。

* **看不到文件／权限不对**：

  * 调整 `uid=$(id -u)`、`gid=$(id -g)` 或 `file_mode=0664,dir_mode=0775`。

* **挂载很慢或断开**：

  * 在挂载选项里加上 `noatime,_netdev`。
  * 网络防火墙／交换机是否限速或断开。

执行完以上步骤，你就可以在 `/mnt/volume1_FalconCoreData`、`/mnt/volume2_FalconCoreDatasets`、`/mnt/volume3_FalconCorePPT` 这三个目录下，直接访问 NAS 三个存储池中的共享了。

