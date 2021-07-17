#!/bin/bash
NOTIFICATION_GATE="{{ smart_home_script_dir }}/notificationGate.sh"
# Wait for networks
sleep 30
$NOTIFICATION_GATE "Reboot $(hostname --short)" "$(hostname --short) rebooted"
