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
