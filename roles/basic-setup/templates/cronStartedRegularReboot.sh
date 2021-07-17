#!/bin/bash
NOTIFICATION_GATE="{{ smart_home_script_dir }}/notificationGate.sh"
$NOTIFICATION_GATE "regularer Reboot" "..in 5 Seconds $(date)"
sleep 5
echo "Reboot at $(date) "
sudo /sbin/reboot
