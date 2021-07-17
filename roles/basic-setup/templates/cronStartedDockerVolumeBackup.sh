#!/bin/bash
NOTIFICATION_GATE="{{ smart_home_script_dir }}/notificationGate.sh"

#########################################################################
#
# Backupscript for Dockvolumes
#
#########################################################################

BACKUPS_TO_KEEP=5             # Maximale Backups die aufbewahrt werden sollen
MAX_STORAGE_PERCENT=85        # Maximaler Speicherplatz in  ist dieser ueberschritten, wird eine Warnung versendet
MAIL_EMPF={{ notification.recipient }}   # EMail-Empfänger
SEND_MAIL_AFTER_FINISHED="Y"  # could be (Y)es or (N)o sein,
                              # if Y EMail is send after Backup to {{ notification.recipient }} N just output

# Quelle des Backups muss das Verzeichnis sein, wo alle
# Docker-Container die Daten persistiern
BACKUP_SOURCE="{{ smart_home_data_dir }}"

# Wichig ! Hier muss ein / am Ende sein ... Backup-Ziel
# Important  ! add / at the end
BACKUP_DEST="{{ smart_home_backup_dir }}/"

# exclude Option fuer tar, weitere Verzeichniss mit --exclude angeben, also
#z.B. --exclude=/xy --exclude=/bla
# Achtung: die Pfade gelten relativ vom tar, befinde ich mich im Verzechnis
#           /mnt/externalSSD/DockerVolumes so exkludiere ich
#           Aufnahmen/* und nicht /mnt/externalSSD/DockerVolumes/Aufnahmen/*
# BACKUP_EXCLUDE="--exclude=*not-to-backup* "

BACKUP_EXCLUDE=""

DRY_RUN="N" # (Y)es or (N)o

##########################################################################
# Pfade und Einstellungen
##########################################################################

if [ $(id -u) -gt 0 ] ;then
    echo "Use sudo $0 "
    exit 1
fi

MAIL_FROM=$(whoami)@$(hostname --short)       # Sender der Email
SENDMAIL=/usr/sbin/sendmail
GREP=/usr/bin/grep
TAR=/bin/tar
PRETTY_TIME_STAMP='+%d %b %Y,%H:%M:%S'
PRETTY_START_TIME=$(date "+%d.%m.%Y um %H:%M Uhr")
TAR_NAME="${BACKUP_DEST}$(date "+%Y-%m-%d_%H_%M_%S").tar.gz"
LOG_BODY=/tmp/log_of_backup.txt
LOG_HEADER=/tmp/log_of_backup_header.txt
MAIL_HEADER=/tmp/mail_header.txt
DOCKER=/usr/bin/docker
#########################################################
# Helper functions
#########################################################
function timeStamp ()
{
  echo $(date "+%d %b %Y,%H:%M:%S ")
}
function appendBodyTxt () {
  echo "$1" >> ${LOG_BODY}
}
function appendBlankLineToBody(){
  echo "$1"  >> ${LOG_BODY}
}
function appendHeaderTxt () {
  echo "$1" >> ${LOG_HEADER}
}
function appendMailMetaData () {
  echo "$1" >> ${MAIL_HEADER}
}
########################################################
function checkExitStatusAndTerminateIfFail ()
{
   if [ $1 -ne 0  ] ;then
     appendBodyTxt "Errorcode $1 at Step $2 "
  fi
}
########################################################
function createAndCheckTar ()
{
   SOURCE=$1
   DEST=$2
   appendBodyTxt "cd ${SOURCE} && ${TAR} '${BACKUP_EXCLUDE}' -cvzf ${TAR_NAME} * && cd - "
   cd ${SOURCE}
   ${TAR} ${BACKUP_EXCLUDE} -hcvzf ${TAR_NAME} * 2>&1> /dev/null
   cd -
   echo "Check Tar ${TAR_NAME}"
   ${TAR} -xOf ${TAR_NAME} 2>&1>/dev/null
   RESULT=$?
   if [ $RESULT -eq 0  ] ;then
    appendBodyTxt "Tar OK: $TAR_NAME "
   else
    appendBodyTxt "Tar Errorcode $RESULT by $TAR_NAME "
   fi
   return $RESULT
}
########################################################
function checkPercentUsage ()
{
  CHECK_PATH=$1
  MAX_PERCENT=$2
  ACTUAL_PERCENT=$(df -k $CHECK_PATH | awk '{print substr ($5,1,length($5)-1) }' | tail -n 1)
  appendHeaderTxt "actual used storage ${CHECK_PATH} => ${ACTUAL_PERCENT}%"
  if [ $ACTUAL_PERCENT -gt $MAX_PERCENT ] ; then
     appendHeaderTxt "############## WARNING ####################################################"
     appendHeaderTxt " "
     appendHeaderTxt "storage is less  .... "
     appendHeaderTxt "limit ${MAX_PERCENT}% reached: actual ${ACTUAL_PERCENT}%"
     appendHeaderTxt " "
     appendHeaderTxt "###########################################################################"
  fi
}
###################################################################################################
#
# Selfmade Backupscript fuer Docker
#
###################################################################################################
# truncate logs
> ${LOG_BODY}
> ${LOG_HEADER}
> ${MAIL_HEADER}
###################################################################################################

echo "Docker-Backup starts"
if [ $DRY_RUN = "Y" ] ; then
  echo "----------------------------------------------"
  echo "DRY-RUN --------------------------------------"
  echo "----------------------------------------------"
fi

START_TIME=$(date +%s)
$NOTIFICATION_GATE "Docker-Backup starts " "Backup starts at $(date) (DRY_RUN=${DRY_RUN})"

if [ $DRY_RUN = "Y" ] ; then
  appendBodyTxt "--------------------- No actions -------------------------"
  appendBodyTxt "no actions with DRY_RUN=${DRY_RUN} "
  appendBodyTxt "--------------------------------------------------------------"

fi
appendBodyTxt "Docker-Backup starts (DRY_RUN=${DRY_RUN}) at $(date)..."
appendBodyTxt "Backups to keep: ${BACKUPS_TO_KEEP} "
appendBodyTxt "Maximal storage: ${MAX_STORAGE_PERCENT}%"
appendBodyTxt "Source:          ${BACKUP_SOURCE}"
appendBodyTxt "Dest:            ${BACKUP_DEST} "
appendBodyTxt "Exclude:         ${BACKUP_EXCLUDE}"
appendBodyTxt "Mail-Recipient:  ${MAIL_EMPF}"
appendBodyTxt "Mail-sender:     ${MAIL_FROM}"
appendBodyTxt "send Mail :      ${SEND_MAIL_AFTER_FINISHED}"
# alle laufenden Container bestimmen
{% raw %}
RUNNING_CONTAINER=$($DOCKER container ls --format '{{.Names}}')
{% endraw %}
echo "Stopping Container"
appendBodyTxt "------------ Backup --------------------------"

# alle laufenden Container stoppen
appendBodyTxt "Stopping Docker-Container"
for container in ${RUNNING_CONTAINER} ; do
  appendBodyTxt "Stopping => $container " >> ${LOG_BODY}
  if [ $DRY_RUN = "N" ]; then
    echo "Stopping => $container "
    $DOCKER container stop $container 2>&1>> ${LOG_BODY}
  else
     echo "Dry-run, keep Container running $container"
  fi
done


# Das Verzeichnis packen und testen
appendBodyTxt "TAR von ${BACKUP_SOURCE} "

echo "Create Tar .. this will take a while"
if [ $DRY_RUN = "N" ]; then
  createAndCheckTar ${BACKUP_SOURCE} ${BACKUP_DEST}
  TAR_RESULT=$?
else
  echo "Dry-run: skipping Tar"
fi

# die zuvor bestimmten Container wieder starten
appendBodyTxt "Start Docker-Containers"

echo "Start Containers"

for container in ${RUNNING_CONTAINER} ; do
  appendBodyTxt "Starting => $container " >> ${LOG_BODY}
  if [ $DRY_RUN = "N" ]; then
    echo "Starte => $container "
    $DOCKER container start $container 2>&1>> ${LOG_BODY}
  else
     echo "Dry-run, Container still running $container"
  fi
done

# Prüfen, was der TAR ergab
if [ $DRY_RUN = "N" ]; then
  checkExitStatusAndTerminateIfFail $TAR_RESULT "Tar Docker"
fi

# Aufräumen
appendBodyTxt "------------ Housekeeping --------------------------"
appendBodyTxt "actual Backup "
ls -la ${BACKUP_DEST} >> ${LOG_BODY}
appendBodyTxt "Backups to keep $BACKUPS_TO_KEEP "
for backToDel in $(ls ${BACKUP_DEST} | head -n -${BACKUPS_TO_KEEP})
do
  appendBodyTxt "Delete old Backups $backToDel"
  echo "delets $backToDel"
  if [ $DRY_RUN = "N" ]; then
    rm ${BACKUP_DEST}/$backToDel
  else
    echo "Dry-run do nothing with ${BACKUP_DEST}/$backToDel "
  fi
done

END_TIME=$(date +%s)
RUN_TIME=$((END_TIME-START_TIME))
appendBlankLineToBody
appendBlankLineToBody
appendBodyTxt "Backup took ${RUN_TIME} Seconds at $(date)..."
appendBodyTxt "... with a lot of fun :-) "
# Die komplette Mail aufbauen
appendMailMetaData "From: ${MAIL_FROM}"
appendMailMetaData "To: ${MAIL_EMPF}"
SUBJECT="Subject: Protocol Backup Docker-Volumes at $(hostname -s ) from $(date "+%A, %d %B %Y") "
appendMailMetaData "${SUBJECT}"
appendMailMetaData "MIME-Version: 1.0 "
appendMailMetaData "Content-Type: text/html "
appendMailMetaData "Content-Disposition: inline "
appendMailMetaData "<html> "
appendMailMetaData "<body> "
appendMailMetaData "<pre style=\"font: monospace\"> "


appendHeaderTxt "Hello,"
appendHeaderTxt " "
appendHeaderTxt "the Backupscript for your Docker-Volumes at $(hostname -s) finished."
appendHeaderTxt "It took ${RUN_TIME} Sec."
appendHeaderTxt "Actual amount of Backups $(du -sh ${BACKUP_DEST} | awk '{print $1}' ) "
checkPercentUsage ${BACKUP_DEST} ${MAX_STORAGE_PERCENT}

USED=$(df -k $BACKUP_DEST | awk '{print substr ($5,1,length($5)-1) }' | tail -n 1)
echo "Disk summary: Used ${USED}%  ($(du -sh ${BACKUP_DEST} | awk '{print $1}') )"
echo "------------------------- Backups -------------------------------"
ls -la ${BACKUP_DEST}


# Alles OK, noch die Mail senden, dazu legen wir erst mal beide Files zusammen
cat ${LOG_HEADER} >> ${MAIL_HEADER}
cat ${LOG_BODY} >> ${MAIL_HEADER}
appendMailMetaData "</pre> </body> </html> "

echo "Backup ends"
# im MAIL_HEADER ist nun alles drin
if [ $SEND_MAIL_AFTER_FINISHED = "Y" ] ; then
  $SENDMAIL -t  < ${MAIL_HEADER}
fi

$NOTIFICATION_GATE "Docker-Backup ends (DRY-RUN=${DRY_RUN})" "Docker-Backup ends $(date) after $RUN_TIME Seconds\n\
actual storage  ${BACKUP_DEST} \n\
$(df -k $BACKUP_DEST | awk '{print substr ($5,1,length($5)) }' | tail -n 1)\n\
Tar: ${TAR_NAME}"

