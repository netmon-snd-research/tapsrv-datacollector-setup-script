# Description
The script willl setup `zeek` from [opensuse-zeek](https://software.opensuse.org/download.html?project=security%3Azeek&package=zeek-lts) on your machine. Tested on Ubuntu 24.04.1 LTS amd64. After installation completed you can check `/opt/zeek/` and the binary is on `/opt/zeek/bin`. Check if the zeek is installed with `zeek -h` command. Check your ubuntu version with `lsb_release -a` on ubuntu. 

# Configuration
After zeek is installed please modify your configuration
- Edit the capture interface on `/opt/zeek/etc/node.cfg`.
- Modify your log dir on `/opt/zeek/etc/zeekctl.cfg` `LogDir` variable or just use default log dir.
- Add these line below to `./zeek/share/zeek/site/local.zeek`
  ```bash
  # @load packages
  @load frameworks/files/extract-all-files
  redef ignore_checksums=T;     # make sure that zeek ignore checksums 
  ```
  Notice, to comment `# @load packages` on `./zeek/share/zeek/site/local.zeek`
- last, run this command 
  ```bash
  zeekctl check
  ```
  If the output is "zeek scripts are ok." so zeek is ready to use. 

## Available OS on This Installation Script
- Ubuntu 20.04
- Ubuntu 22.04
- Ubuntu 24.04
- Ubuntu 24.10
- Ubuntu 25.04

# Manual Installation
If you want to install it manually you can use this command below or just refer to this [url](https://software.opensuse.org/download.html?project=security%3Azeek&package=zeek-lts) directly.


## Ubuntu 25.04
```bash
echo 'deb http://download.opensuse.org/repositories/security:/zeek/xUbuntu_25.04/ /' | sudo tee /etc/apt/sources.list.d/security:zeek.list
curl -fsSL https://download.opensuse.org/repositories/security:zeek/xUbuntu_25.04/Release.key | gpg --dearmor | sudo tee /etc/apt/trusted.gpg.d/security_zeek.gpg > /dev/null
sudo apt update
sudo apt install zeek-lts
```

## Ubuntu 24.10
```bash
echo 'deb http://download.opensuse.org/repositories/security:/zeek/xUbuntu_24.10/ /' | sudo tee /etc/apt/sources.list.d/security:zeek.list
curl -fsSL https://download.opensuse.org/repositories/security:zeek/xUbuntu_24.10/Release.key | gpg --dearmor | sudo tee /etc/apt/trusted.gpg.d/security_zeek.gpg > /dev/null
sudo apt update
sudo apt install zeek-lts
```

## Ubuntu 24.04
```bash
echo 'deb http://download.opensuse.org/repositories/security:/zeek/xUbuntu_24.04/ /' | sudo tee /etc/apt/sources.list.d/security:zeek.list
curl -fsSL https://download.opensuse.org/repositories/security:zeek/xUbuntu_24.04/Release.key | gpg --dearmor | sudo tee /etc/apt/trusted.gpg.d/security_zeek.gpg > /dev/null
sudo apt update
sudo apt install zeek-lts
```

## Ubuntu 22.04
```bash
echo 'deb http://download.opensuse.org/repositories/security:/zeek/xUbuntu_22.04/ /' | sudo tee /etc/apt/sources.list.d/security:zeek.list
curl -fsSL https://download.opensuse.org/repositories/security:zeek/xUbuntu_22.04/Release.key | gpg --dearmor | sudo tee /etc/apt/trusted.gpg.d/security_zeek.gpg > /dev/null
sudo apt update
sudo apt install zeek-lts
```

## Ubuntu 20.04
```bash
echo 'deb http://download.opensuse.org/repositories/security:/zeek/xUbuntu_20.04/ /' | sudo tee /etc/apt/sources.list.d/security:zeek.list
curl -fsSL https://download.opensuse.org/repositories/security:zeek/xUbuntu_20.04/Release.key | gpg --dearmor | sudo tee /etc/apt/trusted.gpg.d/security_zeek.gpg > /dev/null
sudo apt update
sudo apt install zeek-lts
```

