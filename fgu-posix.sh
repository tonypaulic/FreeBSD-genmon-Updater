#!/bin/sh
# genmon update notifier and processor (POSIX sh)
# requires: xfce4-genmon-plugin xfce4-terminal xdotool xseticon

##############################################################
# CONFIGURABLE ITEMS
#
# panel icon to use to indicate update status
ICON_UPDATES_AVAILABLE="freebsd-ua"
ICON_UPTODATE="freebsd-nu"
#
# icon to use in notification bubble when notifying of updates
ICON_NOTIFY="freebsd-ua"
#
# custom icon for terminal window (full path to png file)
WIN_ICON="$HOME/.icons/freebsd-daemon.png"
#
# terminal color options (foreground and background)
FG="#FF7F7F"
BG="#000000"
#
# location of secondary and tertiary execution files
FGU2="/tmp/fgu2.sh"
FGU3="/tmp/fgu3.sh"
##############################################################

# find the genmon plugin id for the refresh event
PLUGIN_ID=$(xfconf-query -c xfce4-panel -lv | grep $(basename $0) | awk '{print $1}' | tr -dc '0-9')

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

# create a tertiary file to run iconclick with command and also change icon using xseticon
cat << EOF > "$FGU3"
#!/bin/sh
xfce4-terminal --disable-server -T 'System Update' \\
	--color-bg '$BG' --color-text '$FG' -e "$FGU2" &
PID=\$!
WID=\$(timeout 5 xdotool search --sync --onlyvisible --pid "\$PID" | head -n 1)
if [ -n "\$WID" ]; then
	xseticon -id "\$WID" "$WIN_ICON"
fi
EOF
chmod +x "$FGU3"

# set default values for update counts
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
printf '<iconclick>%s</iconclick>' "$FGU3"
printf '<tool>%b</tool>\n' "$TOOL"

exit 0