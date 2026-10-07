#!/bin/bash
# genmon update notifier and processor
# requires: xfce4-genmon-plugin

##############################################################
# CONFIGURABLE ITEMS
#
# panel icon to use when updates are available
ICON_UPDATES_AVAILABLE="freebsd-ua"
#
# panel icon to use when system is up to date
#
ICON_UPTODATE="freebsd-nu"
#
# icon to use in notification bubble when notifying of updates
ICON_NOTIFY="freebsd-ua"
#
# location of secondary execution file
FGU2="/tmp/fgu2.sh"
##############################################################

# For Tesitng - enable logging and debug
#exec > >(tee -a /tmp/fgu_debug.log) 2>&1
#set -x

# create secondary execution file to run update script and refresh plugin
cat << EOF > $FGU2
#!/bin/bash
sudo freebsd-update install
	#for REPO in FreeBSD-ports FreeBSD-ports-kmods; do
	#	sudo pkg upgrade -y -r "\$REPO"
	#done
sudo pkg upgrade
echo 
echo \"===== Done - Press enter to exit =====\"
read
xfce4-panel --plugin-event=genmon-$(xfconf-query -c xfce4-panel -lv | grep fgu | awk '{print $1}' | tr -dc '0-9'):refresh:bool:true
exit 0
EOF
chmod +x $FGU2

FREEBSD_UPDATES=0
PKG_UPDATES=0

# get freebsd updates informtation
sudo freebsd-update --not-running-from-cron fetch 
FREEBSD_UPDATES_READY="$(sudo freebsd-update updatesready)"
if echo "$FREEBSD_UPDATES_READY" | grep "updates available to install" > /dev/null; then
	echo FREEBSD_UPDATES=1
	fi

# get pkg updates
sudo pkg update
PKG_UPDATES=$(pkg version -vRL= | grep '<' | wc -l)
[[ $PKG_UPDATES -gt 0 ]] && FREEBSD_UPDATES=1

# set genmon icons and tooltip, and notify if updates exist
if [[ $FREEBSD_UPDATES -eq 1 || $PKG_UPDATES -eq 1 ]]; then
	ICON=$ICON_UPDATES_AVAILABLE
	TOOL="<b>Updates are available</b>\n\n"
	TOOL+="<small>base = $FREEBSD_UPDATES\npkg  = $NUM</small>"
	notify-send -i $ICON_NOTIFY "System Status" "Updates are available"
else
	ICON=$ICON_UPTODATE
	TOOL="<b>System is up to date</b>\n\n"
	TOOL+="<small>$(uname -sr)\n\n$(pkg stats | head -3)</small>"
fi

# do the genmon
echo "<icon>$ICON</icon>"
echo -e "<iconclick>xfce4-terminal -T 'Sysytem Update' --color-bg '#000000' --color-text '#3f8ae5' --icon update -e $FGU2</iconclick>"
echo -e "<tool>$TOOL</tool>"
	
exit 0