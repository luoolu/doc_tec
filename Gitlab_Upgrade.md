# GitLab 升级指南

## 升级概述
本文档详细描述了从 GitLab 13.12.15 版本升级到 17.10 版本的关键步骤和命令。升级过程分为多个阶段，涉及多个中间版本的逐步升级，同时包括操作系统从 Ubuntu 20.04 升级到 22.04 的操作。

## 升级路径
13.12.15 → 14.10.5 → 15.0.5 → 15.1.6 → 15.4.6 → 15.11.13 → 16.0.8 → 16.1.5 → 16.2.8 → 16.3.6 → 16.7.z → 16.11.10 → 17.3.7 → 17.5.5 → 17.8.5 → 17.10

## 升级前准备
在开始升级之前，请确保完成以下准备工作：
- 备份当前的 GitLab 数据和配置文件。
- 检查服务器的硬件资源是否满足新版本的最低要求。
- 确保服务器的时间同步正确，以避免因时间问题导致的升级异常。

## 关键步骤与命令

### 1. 初始版本升级到 14.10.5
```bash
# 下载并安装 GitLab 14.10.5 版本的 DEB 包
sudo dpkg -i gitlab-ce_14.10.5-ce.0_amd64.deb

# 重新配置 GitLab 服务
sudo gitlab-ctl reconfigure

# 重启 GitLab 服务
sudo gitlab-ctl restart

# 验证当前版本
cat /opt/gitlab/embedded/service/gitlab-rails/VERSION
```

### 2. 从 14.10.5 升级到 15.0.5
```bash
# 下载并安装 GitLab 15.0.5 版本的 DEB 包
sudo dpkg -i gitlab-ce_15.0.5-ce.0_amd64.deb

# 重新配置并重启服务
sudo gitlab-ctl reconfigure && sudo gitlab-ctl restart

# 检查版本
cat /opt/gitlab/embedded/service/gitlab-rails/VERSION
```

### 3. 操作系统升级（Ubuntu 20.04 到 22.04）
在升级到 GitLab 16.1.5 之后，需要将操作系统从 Ubuntu 20.04 升级到 22.04：
```bash
# 更新当前系统软件包
sudo apt update && sudo apt upgrade -y

# 执行发行版升级
sudo do-release-upgrade
```

### 4. 后续版本升级示例（以 16.1.5 到 16.2.8 为例）
```bash
# 下载并安装目标版本的 DEB 包
sudo dpkg -i gitlab-ce_16.2.8-ce.0_amd64.deb

# 重新配置并重启 GitLab 服务
sudo gitlab-ctl reconfigure && sudo gitlab-ctl restart

# 验证版本号
cat /opt/gitlab/embedded/service/gitlab-rails/VERSION
```

## 注意事项
- 每次升级前，建议先在测试环境中进行验证，确保升级流程和应用兼容性。
- 对于每个中间版本的升级，都需要执行 `reconfigure` 和 `restart` 操作，以确保服务正常运行。
- 如果在升级过程中遇到依赖问题或版本不兼容的情况，可能需要手动调整软件包或联系官方支持。

通过遵循上述步骤，可以逐步将 GitLab 从 13.12.15 版本安全升级到最新的 17.10 版本，同时确保服务器环境的稳定性和数据的完整性。




## gitlab升级，关键步骤和命令
15个版本
13.12.15升级到14.10.5 → 15.0.5 → 15.1.6 → 15.4.6 → 15.11.13 → 16.0.8 → 
16.1.5(GLIBC,Ubuntu 20.04的2.31; 升级到Ubuntu 22.04 LTS（Jammy Jellyfish）sudo apt update && sudo apt upgrade -y
sudo do-release-upgrade)
→ 16.2.8 → 16.3.6 → 16.7.z →16.11.10 → 17.3.7→ 17.5.5→ 17.8.5→ 17.10
## 关键步骤和命令
sudo dpkg -i gitlab-ce_14.0.12-ce.0_amd64.deb
sudo gitlab-ctl reconfigure
sudo gitlab-ctl restart

cat /opt/gitlab/embedded/service/gitlab-rails/VERSION

sudo apt update && sudo apt upgrade -y

## 问题
正在解压 gitlab-ce (16.2.8-ce.0) 并覆盖 (16.1.5-ce.0) ...
dpkg: 处理软件包 gitlab-ce (--install)时出错：
 已安装 gitlab-ce 软件包 post-installation 脚本 子进程返回错误状态 1
在处理时有错误发生：
 gitlab-ce
## 解决方案
GLIBC,Ubuntu 20.04的2.31; 升级到Ubuntu 22.04 LTS（Jammy Jellyfish


gitlab_rails['rack_attack_git_basic_auth'] = {
  'enabled' => true,
 'ip_whitelist' => ['10.122.161.210','10.122.161.197','10.122.161.208','10.122.161.19','10.122.161.142','10.122.161.156'],
  'maxretry' => 10,
  'findtime' => 60,
  'bantime' => 3600
}
gitlab_rails['monitoring_whitelist'] = ['127.0.0.0/8', '192.168.0.1', '10.122.161.210','10.122.161.197','10.122.161.208','10.122.161.19','10.122.161.142','10.122.161.156']

sudo apt update
sudo apt install iptables-persistent

sudo iptables -F
sudo iptables -X


sudo iptables -A INPUT -s 10.122.161.210 -j ACCEPT
sudo iptables -A INPUT -s 10.122.161.197 -j ACCEPT
sudo iptables -A INPUT -s 10.122.161.208 -j ACCEPT
sudo iptables -A INPUT -s 10.122.161.19 -j ACCEPT
sudo iptables -A INPUT -s 10.122.161.142 -j ACCEPT
sudo iptables -A INPUT -s 10.122.161.156 -j ACCEPT
sudo netfilter-persistent save

sudo iptables -F

sudo iptables -L -n --line-numbers
sudo iptables -A INPUT -i lo -j ACCEPT
sudo iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
sudo iptables -A INPUT -p tcp --dport 22 -j ACCEPT

sudo ufw allow from 10.122.161.210 to any port 80
sudo ufw allow from 10.122.161.210 to any port 443
sudo ufw allow from 10.122.161.197 to any port 80
sudo ufw allow from 10.122.161.197 to any port 443
sudo ufw allow from 10.122.161.208 to any port 80
sudo ufw allow from 10.122.161.208 to any port 443
sudo ufw allow from 10.122.161.19 to any port 80
sudo ufw allow from 10.122.161.19 to any port 443
sudo ufw allow from 10.122.161.142 to any port 80
sudo ufw allow from 10.122.161.142 to any port 443
sudo ufw allow from 10.122.161.156 to any port 80
sudo ufw allow from 10.122.161.156 to any port 443

sudo iptables -A INPUT -p tcp --dport 80 -j DROP
sudo iptables -A INPUT -p tcp --dport 443 -j DROP

sudo netfilter-persistent save
sudo netfilter-persistent reload



# 保存当前规则
sudo netfilter-persistent save

# 加载已保存的规则
sudo netfilter-persistent reload
# 重启服务
sudo systemctl restart netfilter-persistent

# 启用开机自启
sudo systemctl enable netfilter-persistent

sudo ufw allow from 192.168.1.100 to any  # 允许指定IP访问所有端口
sudo ufw enable

sudo ufw allow from 10.122.161.210 to any
sudo ufw allow from 10.122.161.197 to any
sudo ufw allow from 10.122.161.208 to any
sudo ufw allow from 10.122.161.19 to any
sudo ufw allow from 10.122.161.142 to any
sudo ufw allow from 10.122.161.156 to any
sudo ufw enable



根据你的操作，问题出在手动添加的`DROP`规则覆盖了`ufw`的允许规则，并且可能未正确配置SSH规则。以下是解决步骤：

### 步骤 1：恢复SSH访问
首先，确保SSH端口22允许所有连接：

```bash
sudo iptables -I INPUT -p tcp --dport 22 -j ACCEPT
```

### 步骤 2：删除手动添加的DROP规则
移除可能导致网页无法访问的`DROP`规则：

```bash
sudo iptables -D INPUT -p tcp --dport 80 -j DROP
sudo iptables -D INPUT -p tcp --dport 443 -j DROP
```

### 步骤 3：检查并启用UFW规则
确保`ufw`规则正确并启用：

```bash
sudo ufw enable
sudo ufw reload
```

### 步骤 4：设置默认策略（可选）
如果INPUT链默认不是DROP且需要严格限制：

```bash
sudo iptables -P INPUT DROP
```

### 步骤 5：确保规则顺序正确
确保`ufw`的允许规则在默认拒绝之前。使用UFW管理80/443端口，无需手动添加`DROP`。

### 步骤 6：保存并应用配置
```bash
sudo netfilter-persistent save
sudo netfilter-persistent reload
```

### 验证规则
检查规则是否正确：

```bash
sudo iptables -L INPUT -n --line-numbers
sudo ufw status verbose
```

### 总结
通过以上步骤，SSH和网页访问应恢复正常。确保仅通过`ufw`管理端口访问，避免混合使用`iptables`命令，防止规则冲突。




