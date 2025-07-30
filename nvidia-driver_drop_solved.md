## check gcc version
## sudo sh cuda_11.6.2_510.47.03_linux.run -- ## gcc-10 ##
sudo update-alternatives --config gcc

sudo apt-get purge *nvidia* -y
sudo apt-get autoremove *nvidia* -y
sudo apt-get update && sudo apt-get autoremove && sudo apt-get autoclean -y


apt search nvidia-driver


sudo apt install libnvidia-common-470
sudo apt install libnvidia-gl-470


sudo apt install nvidia-driver-470
sudo reboot

nvidia-smi

********************************************
## second methods

ubuntu-drivers devices

sudo apt install nvidia-driver-470

sudo reboot

nvidia-smi

****************************     NVLink A800     ****************

$ sudo apt install nvidia-driver-550

$ sudo reboot

$ nvidia-smi

$ " version=550.90.07
main_version=$(echo $version | awk -F '.' '{print $1}')
sudo apt-get -y install nvidia-fabricmanager-${main_version}=${version}-* "

$ sudo systemctl enable nvidia-fabricmanager

$ sudo systemctl restart nvidia-fabricmanager

$ sudo systemctl status nvidia-fabricmanager

************************************** gpt4.1 **************************
您的 `nvidia-smi` 报错信息：

```
Failed to initialize NVML: Driver/library version mismatch
NVML library version: 535.247
```

**原因分析：**
- 该错误通常是由于 NVIDIA 驱动和 NVML 库（用于管理 GPU）的版本不匹配导致的。这通常发生在升级或重新安装了 CUDA、驱动后，部分库文件未正确更新。

**解决方案：**

1. **确认当前驱动版本：**
   ```bash
   cat /proc/driver/nvidia/version
   ```

2. **检查 CUDA 和驱动兼容性：**
   如果 CUDA Toolkit 与驱动版本不兼容，也会出现该问题。可以用如下命令查看 CUDA 版本：
   ```bash
   nvcc --version
   ```

3. **重新安装 NVIDIA 驱动（推荐用官方 .run 安装包或 apt）：**
   - 卸载旧驱动：
     ```bash
     sudo apt-get remove --purge nvidia-*
     ```
   - 更新并安装推荐驱动：
     ```bash
     sudo apt update
     sudo ubuntu-drivers devices
     sudo apt install nvidia-driver-535
     ```
     （如显示推荐其他版本，请用推荐版本）

4. **重启系统：**
   ```bash
   sudo reboot
   ```

5. **再次测试：**
   ```bash
   nvidia-smi
   ```

6. **注意：**
   - 如果你使用的是 Docker 或 conda 环境，确保容器/环境中的 CUDA 库和宿主机驱动版本兼容。
   - 有时 `/usr/lib/x86_64-linux-gnu/libnvidia-ml.so.*` 链接指向了错误的 NVML 版本，可以手动修正软连接。

**常见原因总结：**
- 升级 CUDA 后未重新安装驱动。
- 多个驱动版本残留。
- 驱动或 CUDA 安装不完整。

如有特殊环境（如多 CUDA 版本、容器、WSL），请补充说明。











