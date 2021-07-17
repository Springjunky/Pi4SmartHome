## Setup a Pi4 to manage your Smarthome

### Docker based setup
This play configures your Pi4 with

- [Webmin](https://webmin.com/)
- [Postfix and Google-Mail]( https://www.linode.com/docs/guides/configure-postfix-to-send-mail-using-gmail-and-google-workspace-on-debian-or-ubuntu/)

and Docker-Containers
- [IObroker](https://www.iobroker.net/) 
- [Grafana](https://grafana.com/)
- [Influxdb](https://www.influxdata.com/) 
- [Portainer](https://www.portainer.io/)

_Note_:
all Container can reach each other with the hostname of your pi (__not__ localhost).

For Example: IOBroker is able to use inflxdb with http://<your-hostname>:8086 
(see docker.env located in SmarthomeDocker)


and many convenience-Scripts
- reboot your system an send a message
- do a heartbeat message  
- backup your persitence Docker Volumes and send a log for this
- restore your Docker Volumes after system crash

## Steps to get a Smarthome-Pi 
### Step 1 Setup your Pi4 to boot from SSD
See this tutorial: https://www.tomshardware.com/how-to/boot-raspberry-pi-4-usb

or this: https://peyanski.com/how-to-boot-raspberry-pi-4-from-ssd/

or ... happy google ..
#### Optional set hostname
there are many ways to do that: https://pimylifeup.com/raspberry-pi-hostname/

### Step 2 create a Google-Mail account to send Emails from your Pi
I recommend to create an extra Google-Mail account for this, so your origninal account 
would not be affected in any kind of security issues.

A smarthome Pi without the possibility to send Email ist not very usefull .. you need an account.

### Step 3 Optional create an Pushover-Account
Pushover is a very goog Pushup-Message-System with many clients (Android, IOS, .. ) very useful, I recommend to create an account.
If you don't have an account set 'notification.pushover.enabled=false' and some notfications will be sent as an EMail.

### Step 4 customize  setup
all configuration is stored in
```
smarthome_config.yml
```
this file is not very complex, just follow the YAML-Syntax. 

Only the 'notification' section is relevant.

### Step 5 clone & run the Ansible play
```text
git clone .....
sudo ./setupMyPi.sh
```
this will take a while .. 
### Step 6 reboot your system

## Notifications of your Smarthome
Notifications will be sent with Mail and Pushover, configured in the structure
```yaml
notification:
  recipient: "Notification@mysystem.com" #recipient of all system-Emails (eg Webmin)
  postfix_gmail: # Configuration parameters for postfix to send email with google-account
    email: "sample@smarthome.com" # account used to send mails from
    password: "secret" #your password / access token from this account"
  pushover:
    enabled: true # Set false with no pushover account ...
    user:  "place here your username"
    token:  "place here your apitoken"
```

## Notes
#### Webmin
Webmin is configured _without_ https, an updates every day your system.
Notifications about package-updates will be sent to 'notification.recipient'


#### Passwords
|Container  | User | Password    | Remark |
|---|---|---|---|
|Portainer| admin | admin | stored in file 'admin_password.txt' and mounted to container|
|Webmin | your smarthome user | your smarthome user password | - |


#### URL's

Every application can be reached with `http://your-hostname:port/` or, when you are directly logged in  
`http://loclhost:port/`

|Application | URL | 
|---|---|
|Webmin | `http://your-hostname:10000/` |
|Portainer | `http://your-hostname:9000/` |
|Influx | `http://your-hostname:8086/` (no gui) |
|Grafana| `http://your-hostname:3000/` |
|Dokuwiki| `http://your-hostname:80/` (http Port)|
|Iobroker| `http://your-hostname:8081/` (Admin-Component) |

#### Scripts

...  to be done ... 

#### Directories

Directories are created in the 'Smart-home-user' - home (default: pi)

|Directory|Content|
|---|---|
|SmarthomeDocker|docker-compos files and end environment|
|SmarthomeScripts| all convinience-Scripts|
|SmarthomeData| all persistence Docker-Volumes |
|SmarthomeDataBackup| .tar.gz Backups of the SmarthomeData content (created with cronjob)|
|SmarthomeDataRestore| Future use|
