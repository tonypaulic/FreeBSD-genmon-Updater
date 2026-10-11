#!/bin/sh
# genmon update notifier and processor (POSIX sh)
# requires: xfce4-genmon-plugin

##############################################################
# CONFIGURABLE ITEMS
#
# panel icon to use when updates are available
ICON_UPDATES_AVAILABLE="freebsd-ua"
#
# panel icon to use when system is up to date
ICON_UPTODATE="freebsd-nu"
#
# icon to use in notification bubble when notifying of updates
ICON_NOTIFY="freebsd-ua"
#
# location of secondary execution file
FGU2="/tmp/fgu2.sh"
##############################################################

# find the genmon plugin id for the refresh event
PLUGIN_ID=$(xfconf-query -c xfce4-panel -lv | grep fgu | awk '{print $1}' | tr -dc '0-9')

# create secondary execution file to run update script and refresh plugin
cat << EOF > "$FGU2"
#!/bin/sh
sudo freebsd-update install
sudo pkg upgrade
echo
echo "===== Done - Press enter to exit ====="
read _dummy
xfce4-panel --plugin-event=genmon-${PLUGIN_ID}:refresh:bool:true
exit 0
EOF
chmod +x "$FGU2"

FREEBSD_UPDATES=No
PKG_UPDATES=0

# get freebsd updates information
sudo freebsd-update --not-running-from-cron fetch > /dev/null
FREEBSD_UPDATES_READY=$(sudo freebsd-update updatesready)
if ! echo "$FREEBSD_UPDATES_READY" | grep -q "No updates are available to install"; then
	FREEBSD_UPDATES=Yes
fi

# get pkg updates
sudo pkg update > /dev/null
PKG_UPDATES_READY=$(pkg version -vRL= | grep -c '<')
if [ "$PKG_UPDATES_READY" -gt 0 ]; then
	PKG_UPDATES_PKGS=$(pkg version -vRL= | grep '<' | awk '{print $1}')
fi

# set genmon icons and tooltip, and notify if updates exist
if [ "$FREEBSD_UPDATES" -eq 1 ] || [ "$PKG_UPDATES_READY" -gt 0 ]; then
	ICON=$ICON_UPDATES_AVAILABLE
	TOOL="<b>Updates are available</b>\n\n"
	TOOL="${TOOL}<small>base = $FREEBSD_UPDATES\n\n"
	TOOL="${TOOL}$PKG_UPDATES_PKGS</small>"
	notify-send -i "$ICON_NOTIFY" "System Status" "Updates are available"
else
	ICON=$ICON_UPTODATE
	TOOL="<b>System is up to date</b>\n\n"
	TOOL="${TOOL}<small>$(uname -sr)\n\n$(pkg stats | head -3)</small>"
fi

# do the genmon
printf '<icon>%s</icon>\n' "$ICON"
printf '<iconclick>xfce4-terminal -T %s --color-bg %s --color-text %s --icon update -e %s</iconclick>\n' \
	"'System Update'" "'#000000'" "'#FF7F7F'" "$FGU2"
printf '<tool>%b</tool>\n' "$TOOL"

exit 0