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
