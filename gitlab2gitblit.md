## 20250324
下面提供一个完整的迁移方案，步骤包括备份、获取仓库列表、批量克隆、安装配置 Gitblit、将仓库导入 Gitblit 以及后续验证和调整。注意：Gitblit 主要是用于 Git 仓库的管理，GitLab 里除代码外的 Issue、CI/CD、Wiki、附件等功能 Gitblit 并不支持，如果非代码内容是以附件或其它形式存在，建议另外备份和处理。以下方案假设所有需要迁移的内容均在 Git 仓库内（比如采用 Git LFS 存储的非代码数据也会跟随仓库迁移）。

---

## 1. 备份 GitLab 数据

在迁移前务必备份 GitLab 数据，以防操作失误导致数据丢失。  
例如（假设 GitLab 安装在 Ubuntu 系统上）：

```bash
# 停止 GitLab 服务（如果需要）
sudo gitlab-ctl stop

# 备份 GitLab 数据目录和配置目录（请根据实际路径调整）
sudo cp -a /var/opt/gitlab /path/to/backup/gitlab_backup
sudo cp -a /etc/gitlab /path/to/backup/gitlab_config_backup

# 如果服务已停止并确认备份无误后，再启动服务
sudo gitlab-ctl start
```

---

## 2. 获取所有 GitLab 仓库的列表

可以通过两种方式获得所有仓库的地址：

### 2.1 通过文件系统查找
如果你的 GitLab 仓库存储在 `/var/opt/gitlab/git-data/repositories` 下，可以生成仓库列表：
```bash
find /var/opt/gitlab/git-data/repositories -name "*.git" > ~/repo_list.txt
```
列表中的每一行为仓库的存储路径，可能需要根据实际情况转为仓库访问 URL（例如：http://gitlab-server/namespace/project.git）。

### 2.2 通过 GitLab API 获取
若你有 API token，可以用下面的命令获取项目的 SSH 地址（安装 jq 工具）：
```bash
curl --header "PRIVATE-TOKEN: <your_access_token>" "http://gitlab.example.com/api/v4/projects?per_page=100" | jq '.[].ssh_url_to_repo' > ~/repo_list.txt
```
请将 `<your_access_token>` 和 URL 替换为实际值。

---

## 3. 批量克隆 GitLab 仓库

利用上一步生成的仓库列表，编写脚本批量克隆（使用 `--mirror` 参数可以完整克隆包括所有分支、标签和 Git 对象的完整仓库）。

例如，创建脚本 `clone_repos.sh`：
```bash
#!/bin/bash
mkdir -p ~/gitlab_mirrors
cd ~/gitlab_mirrors
while read repo; do
    echo "Cloning $repo ..."
    git clone --mirror "$repo"
done < ~/repo_list.txt
```
保存后，赋予执行权限并运行：
```bash
chmod +x clone_repos.sh
./clone_repos.sh
```
这样会在 `~/gitlab_mirrors` 目录下生成所有仓库的镜像目录。

---

## 4. 安装和配置 Gitblit

### 4.1 安装 Java 环境

Gitblit 是基于 Java 的，因此需要先安装 Java（例如 OpenJDK 11）：
```bash
sudo apt update
sudo apt install openjdk-11-jre-headless
```

### 4.2 下载并启动 Gitblit

从 Gitblit 官网或 GitHub 发布页面下载最新版本（以下以 1.9.4 版本为例）：
```bash
wget https://github.com/gitblit/gitblit/releases/download/v1.9.4/gitblit-1.9.4.war -O gitblit.war
```
启动 Gitblit（默认端口 8080）：
```bash
java -jar gitblit.war --port=8080
```
Gitblit 会生成配置文件和数据目录（默认在用户目录下的 `.gitblit` 目录），你可以根据需要修改配置，例如仓库存储路径、认证方式等。

---

## 5. 将仓库导入 Gitblit

Gitblit 可以自动扫描指定目录中的仓库，所以我们可以将之前克隆好的仓库移动或复制到 Gitblit 的仓库目录中。

假设 Gitblit 配置的仓库存储目录为 `/home/gitblit/git_repositories`（你可以在 Gitblit 的配置文件中调整），则执行：
```bash
sudo cp -r ~/gitlab_mirrors/*.git /home/gitblit/git_repositories/
sudo chown -R gitblit:gitblit /home/gitblit/git_repositories/
```
然后，登录 Gitblit Web UI（通常 http://<服务器IP>:8080/），进入 “Repositories” 页面，点击 “Scan” 按钮，Gitblit 会扫描该目录下的所有 Git 仓库并自动导入。

---

## 6. 验证和测试

1. 在 Gitblit 的 Web 界面中检查仓库列表，确保所有项目均已正确显示。
2. 选取一个仓库测试克隆，确认代码、分支和标签都完整：
   ```bash
   git clone http://<gitblit_server>:8080/git/<repo_name>.git
   ```
3. 如果仓库中使用了 Git LFS 进行大文件管理，确认 Git LFS 对象也已正常迁移。

---

## 7. 针对非代码（大数据）内容的注意事项

- 如果非代码内容是存放在 Git 仓库内（例如 Git LFS 管理的二进制文件或其他大文件），上述步骤会一起迁移。
- 如果非代码数据以附件、Wiki 等形式存在于 GitLab，而 Gitblit 无法管理，请额外备份这些数据，并考虑采用其他存储或管理方式。

---

## 8. 更新访问入口（DNS/反向代理）

迁移完毕后，将用户访问地址从 GitLab 切换为 Gitblit 服务器地址。可使用 Nginx 反向代理，例如：
```nginx
server {
    listen 80;
    server_name git.example.com;
    
    location / {
        proxy_pass http://localhost:8080/;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
}
```
保存配置后，重启 Nginx：
```bash
sudo systemctl restart nginx
```

---

## 9. 迁移完成后的工作

- **数据验证**：通知团队成员对关键仓库进行验证，确保所有数据、历史记录和大文件均正确迁移。
- **通知切换**：更新团队内部文档及通知，让大家切换到 Gitblit 地址进行代码管理。
- **后续维护**：定期备份 Gitblit 数据，并根据实际需求调整 Gitblit 配置。

---

以上步骤和命令为一个基本的迁移方案。具体环境可能存在差异，请根据实际情况调整路径、端口和配置参数。迁移大数据量（超过 2T）的过程中建议选用网络和磁盘 I/O 负载较低的时段进行操作，以确保数据完整性和稳定性。








下面是从Ubuntu服务器上的GitLab迁移到Gitblit服务器的详细步骤和完整命令。  
整个过程分为四个阶段：

- **一、安装Gitblit服务器**
- **二、从GitLab备份和导出所有仓库**
- **三、将仓库导入Gitblit**
- **四、验证迁移结果**

---

## 一、安装Gitblit服务器（Ubuntu）

### 1. 安装Java环境（JRE或JDK）
```bash
sudo apt update
sudo apt install openjdk-11-jre-headless -y
```

### 2. 下载Gitblit
访问[Gitblit官网](https://gitblit.github.io/gitblit/)获取最新版本。  
目前最新版本为`1.9.3`，可直接执行：

```bash
wget https://github.com/gitblit/gitblit/releases/download/v1.9.3/gitblit-1.9.3.tar.gz
```

### 3. 解压并安装
```bash
sudo mkdir /opt/gitblit
sudo tar -xzvf gitblit-1.9.3.tar.gz -C /opt/gitblit --strip-components=1
```

### 4. 配置Gitblit服务器
编辑`data/gitblit.properties`文件：

```bash
sudo nano /opt/gitblit/data/gitblit.properties
```

根据需要设置端口、数据路径、用户配置等，例如：

```ini
server.httpPort = 8080
server.httpsPort = 8443
git.repositoriesFolder = /opt/gitblit/data/git
```

### 5. 创建systemd服务来启动Gitblit
创建文件`/etc/systemd/system/gitblit.service`：

```bash
sudo nano /etc/systemd/system/gitblit.service
```

填写：

```ini
[Unit]
Description=Gitblit Server
After=network.target

[Service]
Type=simple
User=root
ExecStart=/usr/bin/java -jar /opt/gitblit/gitblit.jar --baseFolder /opt/gitblit/data
WorkingDirectory=/opt/gitblit
Restart=always

[Install]
WantedBy=multi-user.target
```

启动Gitblit服务：

```bash
sudo systemctl daemon-reload
sudo systemctl enable gitblit
sudo systemctl start gitblit
```

检查服务状态：

```bash
sudo systemctl status gitblit
```

打开浏览器访问：
```
http://your-server-ip:8080
```

---

## 二、从GitLab导出所有仓库（代码和大文件）

由于数据超过2TB，建议使用`git clone --mirror`镜像仓库的方式逐个迁移，避免过大单文件：

### 1. 创建存放仓库镜像的临时目录
```bash
mkdir -p ~/gitlab_repos
cd ~/gitlab_repos
```

### 2. 获取所有仓库的URL列表
使用GitLab API导出项目列表，获取所有的ssh/https地址：

示例（需要将下面的`GITLAB_URL`和`PRIVATE_TOKEN`替换为你实际的GitLab地址和Token）：

```bash
GITLAB_URL="http://gitlab.example.com"
PRIVATE_TOKEN="你的TOKEN"
PER_PAGE=100

# 获取全部仓库（考虑分页）
page=1
while :
do
    curl --header "PRIVATE-TOKEN: $PRIVATE_TOKEN" "$GITLAB_URL/api/v4/projects?per_page=$PER_PAGE&page=$page" | jq -r '.[].ssh_url_to_repo' >> repo_list.txt
    [ $(curl -s --head --header "PRIVATE-TOKEN: $PRIVATE_TOKEN" "$GITLAB_URL/api/v4/projects?per_page=$PER_PAGE&page=$page" | grep -i x-next-page | cut -d' ' -f2 | tr -d '\r') ] || break
    ((page++))
done
```

> ⚠️ **注意**: 需安装`jq`：
> ```bash
> sudo apt install jq
> ```

仓库地址存储在`repo_list.txt`中。

### 3. 批量clone仓库镜像
```bash
cd ~/gitlab_repos
cat repo_list.txt | while read repo_url; do git clone --mirror $repo_url; done
```

以上命令完成后，所有仓库镜像都在`~/gitlab_repos`目录下。

---

## 三、导入仓库到Gitblit

### 1. 将仓库拷贝到Gitblit仓库目录
```bash
sudo cp -r ~/gitlab_repos/*.git /opt/gitblit/data/git/
sudo chown -R root:root /opt/gitblit/data/git
```

### 2. 在Gitblit界面刷新仓库
访问Gitblit Web界面，登录管理员账户（默认账号/密码：admin/admin），然后：

- 进入菜单：`Repositories → Manage Repositories → Refresh`。

Gitblit会自动识别新加入的仓库。

---

## 四、验证迁移

- 在Gitblit Web界面中，逐个确认仓库列表是否完整。
- 随机抽取仓库进行clone或pull验证：

```bash
git clone http://gitblit-server-ip:8080/r/your-repo.git
```

检查数据完整性，确保提交记录和大文件正常。

---

## 迁移注意事项：

- 数据迁移时注意磁盘空间充足。
- 迁移大文件的过程比较耗时，建议使用`rsync`增量同步以提高效率。
- 若存在大文件（如超过数百MB至GB级），建议启用Gitblit的Git LFS扩展支持。

---

以上便是**完整操作步骤**和**详细命令**，你可以逐步执行，完成从GitLab到Gitblit的迁移。










