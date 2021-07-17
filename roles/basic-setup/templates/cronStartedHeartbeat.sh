#!/bin/bash
NOTIFICATION_GATE="{{ smart_home_script_dir }}/notificationGate.sh"

cpuTemp0=$(cat /sys/class/thermal/thermal_zone0/temp)
cpuTemp1=$(($cpuTemp0/1000))
cpuTemp2=$(($cpuTemp0/100))
cpuTempM=$(($cpuTemp2 % $cpuTemp1))

gpuTemp0=$(/opt/vc/bin/vcgencmd measure_temp)
gpuTemp0=${gpuTemp0//\'/º}
gpuTemp0=${gpuTemp0//temp=/}

$NOTIFICATION_GATE "Ping $(date)" "Uptime $(uptime)\nProcesses: $(ps -elf| wc -l)\nCPU Temp: ${cpuTemp1}.${cpuTempM}ºC\nGPU Temp: ${gpuTemp0}"
