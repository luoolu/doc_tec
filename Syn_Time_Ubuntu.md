下面给出一套 **可落地的排错 + 配置流程**，帮助你在 Ubuntu 24 上把系统时间稳定同步到北京时间（UTC+8）。命令均假设以 root 或具有 sudo 权限的帐号执行。
（Ubuntu 24.04 仍默认用 **systemd-timesyncd** 作为 NTP 客户端；如果你手动装过 ntp 或 chrony，需先保证只保留一个时间同步服务） ([Ubuntu 文档][1])

---

## 1 . 确认并设置时区 ➜ Asia/Shanghai

```bash
# 查看当前时区与时间同步状态
timedatectl status

# 若不是 Asia/Shanghai，则修改
sudo timedatectl set-timezone Asia/Shanghai
```

再次 `timedatectl`，应看到 *Time zone: Asia/Shanghai (CST, +0800)*。 ([Ask Ubuntu][2], [tutorials.tinkink.net][3])

---

## 2 . 检查现有时间同步服务

```bash
# systemd-timesyncd 是否在用
timedatectl show-timesync --all | grep "Service"

# 检查 chrony/ntpd 是否已安装
dpkg -l | egrep 'ntp|chrony'
```

* **同时跑多个 NTP 客户端会互相抢锁**。若发现 `ntp` 或 `chrony` 与 `systemd-timesyncd` 并存，请保留其一，移除或停用其余。

```bash
# 例：卸载 ntp，保留 systemd-timesyncd
sudo apt purge ntp
sudo systemctl disable --now ntpd
```

---

## 3 A. 方案 A：使用 systemd‑timesyncd（轻量，默认）

1. **安装/恢复**（若被删除）

   ```bash
   sudo apt install systemd-timesyncd
   ```

2. **配置国内 NTP 池**

   ```bash
   sudoedit /etc/systemd/timesyncd.conf
   # 修改或新增
   [Time]
   NTP=ntp.aliyun.com ntp.tencent.com cn.pool.ntp.org
   FallbackNTP=time1.cloud.tencent.com time2.aliyun.com
   ```

   > 可按需要替换或增补服务器；Aliyun/Tencent 在国内网络时延更低。 ([阿里云][4])

3. **重载并立即同步**

   ```bash
   sudo systemctl restart systemd-timesyncd
   sudo timedatectl timesync-status        # 查看同步细节
   ```

> `System clock synchronized: yes` 和 `NTP synchronized: yes` 表示成功；数分钟后再查，偏差应 ≤几十毫秒。

---

## 3 B. 方案 B：改用 chrony（精度更高、抖动更小）

1. **安装 chrony 并停用其他服务**

   ```bash
   sudo apt install chrony
   sudo systemctl disable --now systemd-timesyncd
   ```

2. **编辑 `/etc/chrony/chrony.conf`**
   把官方源注释掉，改为国内 NTP：

   ```bash
   #pool ntp.ubuntu.com iburst
   server ntp1.aliyun.com iburst
   server ntp2.aliyun.com iburst
   server ntp.tencent.com iburst
   ```

   ([server-world.info][5])

3. **重启 & 验证**

   ```bash
   sudo systemctl restart chrony
   chronyc sources -v        # 查看源状态
   chronyc tracking          # 查看偏差/漂移
   ```

   *Ref time (UTC)* 应显示刚刚的上游时间；*System time* 偏差应很小（<0.1 s）。

---

## 4 . 写入硬件 RTC（可选）

若 BIOS 时钟仍旧错误，可在确认系统时间已准确后写入：

```bash
sudo hwclock --systohc
```

---

## 5 . 常见失败原因与排查

| 症状                                  | 排查点           | 解决办法                                                      |
| ----------------------------------- | ------------- | --------------------------------------------------------- |
| **`System clock synchronized: no`** | 服务没起或端口被占     | `systemctl status systemd-timesyncd` 或 `chrony`，确认只启用一个服务 |
| **延迟很大/不同步**                        | 防火墙拦截 UDP 123 | `sudo ufw allow 123/udp` 或检查云服务器安全组                       |
| **国内访问 pool.ntp.org 很慢**            | 上游服务器跨国       | 改用 `ntp.aliyun.com` / `ntp.tencent.com` 等内地源              |
| **虚拟机时间跳变**                         | 主机与客机时钟不同步    | 给宿主机也配置 NTP，或在虚拟机设置里关闭 “Sync with host”                   |

---

### 一键脚本（示例：保留 systemd‑timesyncd）

```bash
#!/usr/bin/env bash
sudo timedatectl set-timezone Asia/Shanghai
sudo apt purge -y ntp chrony      # 如未安装会忽略
sudo apt install -y systemd-timesyncd
sudo sed -i 's|^#NTP=.*|NTP=ntp.aliyun.com ntp.tencent.com cn.pool.ntp.org|; \
             s|^#FallbackNTP=.*|FallbackNTP=time1.cloud.tencent.com|;' \
             /etc/systemd/timesyncd.conf
sudo systemctl restart systemd-timesyncd
timedatectl timesync-status
```

---

完成以上步骤后，`timedatectl status` 应显示 **NTP service: active, synchronized**，系统时间将持续对齐到北京时间，误差一般维持在数毫秒到几十毫秒之间。

[1]: https://documentation.ubuntu.com/server/how-to/networking/timedatectl-and-timesyncd/?utm_source=chatgpt.com "Synchronise time using timedatectl and timesyncd - Ubuntu Server ..."
[2]: https://askubuntu.com/questions/3375/how-to-change-time-zone-settings-from-the-command-line?utm_source=chatgpt.com "How to change time-zone settings from the command line"
[3]: https://tutorials.tinkink.net/en/linux/how-to-change-timezone-in-centos-7.html?utm_source=chatgpt.com "How to change the time zone in Linux (Ubuntu, Debian, CentOS 7)"
[4]: https://www.alibabacloud.com/help/en/ecs/user-guide/alibaba-cloud-ntp-server/?utm_source=chatgpt.com "Elastic Compute Service:Manage time synchronization services"
[5]: https://www.server-world.info/en/note?f=2&os=Ubuntu_24.04&p=ntp&utm_source=chatgpt.com "Ubuntu 24.04 : Configure NTP Server (Chrony)"
