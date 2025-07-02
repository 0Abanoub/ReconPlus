# 🕵️‍♂️ Bug Bounty Recon Script

A **Bash-based automation tool** to streamline the reconnaissance phase for bug bounty hunting and ethical hacking.  
It automates multiple tasks like port scanning, content discovery, certificate lookup, and even detects **subdomain takeover** candidates.

---

## 🔧 Features

- 🔍 **Nmap scanning** with service/version detection
- 🗂 **Dirsearch**-based directory brute-forcing
- 📜 **crt.sh** certificate enumeration
- ⚠️ **Subdomain takeover detection** for common services (GitHub, Heroku, AWS, etc.)
- 🧾 Auto-generated report with highlights
- 🎛 Supports **multiple modes** and **interactive mode**
- 💡 Lightweight, easy to customize & extend

---

| Mode                | Description                  |
| ------------------- | ---------------------------- |
| `-m nmap-only`      | Run only Nmap scan           |
| `-m dirsearch-only` | Run only Dirsearch scan      |
| `-m crt-only`       | Run only crt.sh cert scan    |
| `-m takeover-only`  | Check for subdomain takeover |
| *(default)*         | Run all scans and checks     |

Interactive Mode:
./recon.sh -i

## 📄 Output All results will be saved under:

~/Desktop/<domain>_recon/
Includes:

nmap results

dirsearch.txt output

crt raw cert data

subdomains.txt (cleaned from crt.sh)

takeover.txt (if any CNAME matches known services)

Final report file

## 📦 Requirements :

nmap
dirsearch
jq
curl
dig (usually from dnsutils)

To install dependencies (on Kali/Debian):

sudo apt install nmap jq curl dnsutils
git clone https://github.com/maurosoria/dirsearch.git

## ⚠️ Disclaimer
This tool is for educational and ethical testing purposes only.
Always have permission before scanning any target.

## 🚀 Usage

```bash
chmod +x recon.sh
./recon.sh -m all target.com
