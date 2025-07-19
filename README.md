# Description
This repo is some instruction for configuring CBR2 data collector on TAP server. `zeek` is optional but `argus` and `netflow` is mandatory. 

## 1. Install and setup argus, nfdump, zeek (optional)
- Argus
  You can follow instruction on `./argus/README.md` 
- netflow
  Just run command 
  ```bash
  sudo apt install nfdump
  ```
  Or if that doesn't work you can install it directly from repositories, please read this [instruction](https://github.com/pmorch/nfdump/blob/master/INSTALL)
- Zeek
  You can follow instruction on `./zeek/README.md`

Please remember to update the configuration according to the instructions in each `README.md`.

## 2. Check Installation and Configuration
The `check-datacollector.sh` script verifies if your data collectors are properly installed and configured.

```bash
sudo chmod +x check-datacollector.sh
sudo ./check-datacollector.sh
```

**What this script does:**
- Checks if Zeek, Argus, and nfpcapd are properly installed by running their help commands
- Verifies Zeek configuration files:
  - `/opt/zeek/etc/node.cfg`: Checks for capture interface configuration
  - `/opt/zeek/etc/zeekctl.cfg`: Checks for the log directory configuration
  - `/opt/zeek/share/zeek/site/local.zeek`: Verifies if ignore_checksums is enabled and file extraction is configured
- Uses color-coded output for better readability

## 3. Schedule Data Collection
The `schedule-datacollector.sh` script sets up automatic scheduling for data collection (`run-datacollector.sh` and `stop-datacollector.sh`). Please change line 36-45, enable your desired tools and set the correct capture interface. Unhas use all tools. 

```bash
sudo chmod +x schedule-datacollector.sh
sudo ./schedule-datacollector.sh
```

**What this script does:**
- Sets timezone to GMT+8 (Jakarta)
- Default schedule: Starts on July 21, 2025, at midnight and runs for 7 days
- Allows customizing the start time and interval by changing the schedule parameter variables
- Creates cron jobs to start and stop data collection at the specified times
- Displays information about which collectors are scheduled to run

## 4. Run Data Collectors
The `run-datacollector.sh` script starts the data collectors based on your configuration.

```bash
sudo chmod +x run-datacollector.sh
sudo ./run-datacollector.sh
```

**What this script does:**
- Creates required output directories automatically
- Starts the enabled data collectors:
  - **Argus**: Creates log rotation and runs with the specified interface
  - **nfpcapd**: Runs with compression (-j), as daemon (-D), and (-S 2) for log directory management. 
  - **Zeek**: Deploys using zeekctl

## 5. Verify Cron Jobs
Check if the scheduling was successful:

```bash
sudo crontab -l
```

You should see entries for both starting and stopping the data collectors at the scheduled times.
