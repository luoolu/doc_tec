一键脚本已生成，内置上传文件中的 13 个去重 IP：

[下载 ](sandbox:/workspace/scratch/8346fcbc1c46/restrict_ssh_vnc_allowlist.sh)

运行：

```bash
sudo bash restrict_ssh_vnc_allowlist.sh
```

脚本会：

* 仅允许白名单 IP 访问 SSH、TCP 5901、5902。
* 自动识别非 22 SSH 端口，同时始终保护 22。
* 保留本机回环访问。
* 当前 SSH 来源不在白名单时拒绝执行，防止失联。
* 不重置 UFW、不改变其他端口策略；已启用 UFW 时自动兼容。
* 配置开机自动生效，并在完成后输出一键回滚命令。
* 可重复执行；更新名单时使用：

```bash
sudo bash restrict_ssh_vnc_allowlist.sh /path/to/allowed_ips.txt
```

建议保持当前 SSH 窗口不关闭，另开一个窗口验证连接。实现方式符合 [Netfilter nftables 规则判定机制](https://www.netfilter.org/projects/nftables/manpage.html)和 [Ubuntu 24.04 UFW 规则语法](https://manpages.ubuntu.com/manpages/noble/man8/ufw.8.html)。
