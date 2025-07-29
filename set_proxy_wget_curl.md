To set up a proxy for wget and curl on Ubuntu 24.04 with your proxy server (http://10.22.96.29:8080), you can configure environment variables. Here’s how you can do it:

### 1. Set Proxy for Current Terminal Session

Run these commands in your terminal:
```bash
export http_proxy="http://10.22.96.29:8080"
export https_proxy="http://10.22.96.29:8080"
export ftp_proxy="http://10.22.96.29:8080"
export no_proxy="localhost,127.0.0.1"
```
This will apply the proxy for wget and curl in the current session.

---

### 2. Make Proxy Permanent (All Users)

Add these lines to `/etc/environment` to set system-wide proxy:
```bash
sudo tee -a /etc/environment <<EOF
http_proxy="http://10.22.96.29:8080"
https_proxy="http://10.22.96.29:8080"
ftp_proxy="http://10.22.96.29:8080"
no_proxy="localhost,127.0.0.1"
EOF
```
Log out and log back in (or reboot) to apply.

---

### 3. Configure wget Specifically

You can also add to your user’s `~/.wgetrc` file:
```bash
echo "http_proxy = http://10.22.96.29:8080/" >> ~/.wgetrc
echo "https_proxy = http://10.22.96.29:8080/" >> ~/.wgetrc
```

---

### 4. Configure curl Specifically

You can add to your user’s `~/.curlrc` file:
```bash
echo "proxy = \"http://10.22.96.29:8080\"" >> ~/.curlrc
```

---

**Note:**  
- Replace `10.22.96.29:8080` with your actual proxy server if it changes.
- If your proxy requires authentication, use `http://username:password@10.22.96.29:8080`.

Let me know if you need a script for this or more details!
