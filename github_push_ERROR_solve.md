'''
(.venv) (base) luolu@loobuntu:~/PycharmProjects/anylabeling$ git push -u origin master
Username for 'https://github.com': luoolu
Password for 'https://luoolu@github.com': 
remote: Support for password authentication was removed on August 13, 2021.
remote: Please see https://docs.github.com/get-started/getting-started-with-git/about-remote-repositories#cloning-with-https-urls for information on currently recommended modes of authentication.
fatal: Authentication failed for 'https://github.com/luoolu/FalconCoreLabeling.git/'
'''
出现这个错误是因为 GitHub 已经不再支持通过账号密码进行 HTTPS 推送认证，需要使用 **Personal Access Token（PAT）** 或 **SSH Key** 来替代密码认证。下面分别给出两种方案的完整步骤，你可以任选其一。

---

## 方案一：使用 Personal Access Token (PAT)

1. **在 GitHub 上创建 PAT**

   * 登录到 GitHub 网站，点击右上角头像 → **Settings** → 左侧栏 **Developer settings** → **Personal access tokens** → **Tokens (classic)** → **Generate new token**。
   * 选择 **repo** 相关权限（至少要有 `repo` 全选），然后点击 **Generate token**。
   * 复制好生成的 token（注意：这个 token 只会显示一次，请妥善保存）。

2. **在本地使用 PAT 进行推送**
   在终端执行推送命令时，输入用户名和 token 即可把 token 当成「密码」使用：

   ```bash
   git push -u origin master
   # Username: luoolu
   # Password: <粘贴你的 PAT>
   ```

   或者，你可以将 remote URL 临时改为在 URL 中直接包含 token（**不推荐写死在脚本里，仅作临时演示**）：

   ```bash
   git remote set-url origin https://luoolu:<YOUR_TOKEN>@github.com/luoolu/FalconCoreLabeling.git
   git push -u origin master
   ```

3. **（可选）配置凭据管理器**
   安装并启用 Git 的 credential helper，之后第一次输入 token 后会被缓存，下次就不用再输：

   ```bash
   # 以 Linux 为例，安装并启用
   git config --global credential.helper store
   # 推送一次时输入用户名 + token，后续就会自动读取 ~/.git-credentials
   ```

---

## 方案二：使用 SSH Key（推荐长期使用）

1. **生成 SSH Key**（如果本地还没有的话）

   ```bash
   ssh-keygen -t ed25519 -C "luoolu@your_email.com"
   # 一路回车（使用默认路径），可选设置 passphrase
   ```

2. **把公钥复制到 GitHub**

   ```bash
   # 查看公钥内容
   cat ~/.ssh/id_ed25519.pub
   ```

   然后登录 GitHub → 头像 → **Settings** → 左侧 **SSH and GPG keys** → **New SSH key**，粘贴公钥内容并保存。

3. **将远程地址改为 SSH 地址**

   ```bash
   # 查看当前 remote
   git remote -v
   # 修改 origin 为 SSH 形式
   git remote set-url origin git@github.com:luoolu/FalconCoreLabeling.git
   ```

4. **测试并推送**

   ```bash
   # 测试 SSH 连接
   ssh -T git@github.com
   # 推送
   git push -u origin master
   ```

---

完成以上任一方案后，再次执行：

```bash
git push -u origin master
```

就可以成功将你本地的新功能推送到自己的 GitHub 仓库了。之后也可以照常：

```bash
# 同步上游更新
git fetch upstream
git merge upstream/master   # 或 git rebase upstream/master
git push origin master
```

祝你推送顺利！

***************************************************
It isn’t a GitHub permissions problem at all but a mis‐configured proxy.  The “CONNECT tunnel failed, response 404” is coming from your proxy URL (`http://127.0.0.1:33331/commands/pac`), not GitHub.  Git doesn’t understand PAC files (that “/commands/pac” path) as a proxy endpoint, so every HTTPS CONNECT to `github.com` is getting a 404 from your local proxy server.

---

### 1. Remove the bad proxy settings
```bash
git config --global --unset http.proxy
git config --global --unset https.proxy
```

### 2. (Re‑)configure a *real* HTTP(S) proxy
If your corporate or local proxy is really at 127.0.0.1 port 33331, point Git at it directly (no PAC file):

```bash
git config --global http.proxy  http://127.0.0.1:33331
git config --global https.proxy http://127.0.0.1:33331
```

Then retry:

```bash
git push -u origin main
```

---

### 3. If you must use a PAC file
Git won’t parse it for you.  You have two choices:

1. **Extract the actual proxy host:port** from the PAC file and configure it as above.  
2. **Use a wrapper** like `proxychains` or `tsocks` which *does* support PAC.  
   ```bash
   proxychains git push -u origin main
   ```

---

### 4. Bypass HTTPS altogether with SSH
If your network lets SSH through (or you can tunnel it), switch your remote to SSH and push over port 22:

1. Generate and add an SSH key to GitHub if you haven’t already:
   ```bash
   ssh-keygen -t ed25519 -C "your.email@example.com"
   # then copy ~/.ssh/id_ed25519.pub into your GitHub “SSH and GPG keys” settings
   ```
2. Change your remote:
   ```bash
   git remote set-url origin git@github.com:luoolu/ParseCZI.git
   ```
3. Push:
   ```bash
   git push -u origin main
   ```

---

### 5. Verify the repo URL
Finally, make sure the repo name on GitHub really is `ParseCZI` (no underscore) or `Parse_CZI` (with underscore).  Whichever it is, your remote must exactly match:

```bash
git remote -v
# origin  https://github.com/luoolu/ParseCZI.git (fetch)
# origin  https://github.com/luoolu/ParseCZI.git (push)
```

Once your proxy is set correctly (or removed) and the URL is right, `git push` will go through.
