# 🚀 Jenkins Odoo CI/CD Project

This project automates the deployment of **Odoo custom modules** using **Jenkins Pipeline (as code)**.  
It pulls modules from GitHub, validates them, updates the Odoo container, restarts it, and sends an email when changes are detected.

---

## 🧩 What It Does
- Pulls or clones your Odoo module from GitHub  
- Checks for syntax or code errors  
- Copies modules to your Odoo container’s `/mnt/extra-addons` path  
- Restarts the Odoo container automatically  
- Sends an email if there are new changes or errors  
- Checks for new commits every 5 minutes (SCM Polling)

---

## 📂 Project Files
| File | Description |
|------|--------------|
| **Jenkinsfile** | Main pipeline script for Jenkins |
| **module_update.sh** | Script that validates, syncs, and restarts Odoo container |
| **repos.txt** | List of module repos for auto polling (one per line) |
| **README.md** | You’re reading it :) |

---

## ⚙️ Prerequisites
- Jenkins installed and running  
- Docker installed  
- Odoo container running (example: `odoo16`)  
- Gmail or any SMTP setup for Jenkins email notifications  

---

## 🐳 Start Your Odoo Container
```bash
docker run -d --name odoo16 \
  -v /mnt/extra-addons:/mnt/extra-addons \
  -p 8069:8069 odoo:16.0
