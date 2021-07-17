#/!bin/bash
PO_USER="{{ notification.pushover.user  }} "
PO_TOKEN="{{ notification.pushover.token  }}"
MAIL_FALLBACK="{{ notification.recipient }}"
SENDER=$(hostname)@$(whoami)
if [ -z "$1" ] ; then
  TITLE="Smarthome-Notification from ${SENDER} "
else
  TITLE=$1
fi
if [ -z "$2" ] ; then
  BODY="no Body"
else
  BODY=$2
fi
for tries in $(seq 1 3)
do
   HTTP_CODE=$( curl -s -o /dev/null --write-out '%{http_code}'  \
                 --form-string "token=$PO_TOKEN" \
                 --form-string "user=$PO_USER" \
                 --form-string "title=${SENDER}: ${TITLE}" \
                 --form-string "message=$(echo -e ${BODY})" \
                 --form-string "sound=none"  \
                 https://api.pushover.net/1/messages.json )
    CURL_RESULT=$?
    if [ "${HTTP_CODE}" -eq 200 ] && [ "${CURL_RESULT}" -eq 0 ] ; then
      exit
    fi
    echo "$(date) Senderror HTTP ${HTTP_CODE} Curl ${CURL_RESULT} " >> {{ smart_home_script_dir }}/$(basename "$0").log
    sleep 10
done
# Mail Fallback
sendmail $MAIL_FALLBACK << EOF
From: {{ansible_hostname}}@{{ smart_home_user }}
Subject: Mail-Fallback Pushover ${SENDER}: ${TITLE}
$(echo -e ${BODY})
.
EOF
