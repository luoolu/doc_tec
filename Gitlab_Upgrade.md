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
