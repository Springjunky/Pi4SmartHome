#/!bin/bash
MAIL="{{ notification.recipient }}"
SENDER=$(hostname)@$(whoami)
if [ -z "$1" ] ; then
  TITLE="no Titel "
else
  TITLE=$1
fi
if [ -z "$2" ] ; then
  BODY="no Body"
else
  BODY=$2
fi
sendmail $MAIL << EOF
From: {{ansible_hostname}}@{{ smart_home_user }}
Subject: Smarthome-Notification from ${SENDER}:${TITLE}
$(echo -e ${BODY})
.
EOF
