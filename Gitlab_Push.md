### gitlab
$ luolu@petrochina.com.cn \
$ 6vNAxVdgR6uM4xD \

问题根源  
你已经在本机生成了 Ed25519 密钥，但 GitLab 服务器（10.122.4.56）并不知道这把公钥，因此它只能用密码方式验证。由于 GitLab 默认关闭了「账号密码登录」（或你的账号被设为「仅允许 SSH Key」），所以即使输入正确的密码也会报 Permission denied。

解决思路  
让 GitLab 服务器认识你的公钥，以后就不再需要输入密码。

一步一步操作

1. 取出你刚才生成的公钥  
   ```bash
   cat ~/.ssh/id_ed25519.pub
   ```
   会打印出一行以 `ssh-ed25519` 开头的内容，把它复制下来（整行）。

2. 登录 GitLab Web 界面  
   用浏览器访问 10.122.4.56，用超级管理员账号登录（你给的邮箱/密码应该可以）。  
   进入「Preferences / Settings → SSH Keys」页面，把刚才复制的公钥粘贴进去，起一个名字（例如 falconcore1），保存即可。

3. 测试免密登录  
   回到终端执行：
   ```bash
   ssh -T git@10.122.4.56
   ```
   第一次会提示：
   ```
   The authenticity of host '10.122.4.56 (10.122.4.56)' can't be established...
   ```
   输入 yes 后如果看到
   ```
   Welcome to GitLab, @Administrator!
   ```
   就说明 SSH Key 已经生效。

4. 以后 clone / push 都走 SSH  
   例如：
   ```bash
   git clone git@10.122.4.56:group/project.git
   ```
   不再需要输入密码。

常见踩坑排查清单  
- 确认复制的是 **公钥**（id_ed25519.pub），不是私钥。  
- 公钥粘贴后不要带多余空格或换行。  
- 如果 GitLab 强制开启了「Use HTTP(S) instead of SSH」，需要在 GitLab Admin Area → Settings → Network → Outbound requests 里关闭「Allow requests to the local network from hooks and services」，或者请管理员检查「Enabled Git access protocols」是否仅允许 HTTPS（改为 Both 或 SSH Only）。  
- 确认你本机 `~/.ssh/config` 没有写错 Host 或 Port，例如：
  ```
  Host 10.122.4.56
      HostName 10.122.4.56
      User git
      IdentityFile ~/.ssh/id_ed25519
  ```

完成以上步骤后，再用 SSH 连接就不会提示输入密码了。
