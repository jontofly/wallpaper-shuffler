#!/bin/bash
# A Script To Configure Desktop Backgrounds changer.

# Vars
StartItDir="$HOME/.config/autostart"
StartItFile="rdeskpics-autostart.desktop"
ScriptDest="$HOME/.rand-desk-pics.sh"
PicsDb="$HOME/.pics-to-rand.txt"
ReScanWeek="5" # WeekDay -> 0=Sun, 1=Mon, 2=Tue, 3=Wed, 4=Thu, 5=Fri, 6=Sat
PicsDirSel=''
SleepFor="30"

# Choose settings.
zenity --info --ok-label="Next" --text="Welcome to the Wallpaper Shuffler Setup\n \
Click Next to choose a directory with images\n\
to be shuffled on the Desktop background.\n\n\
"

SetupFun() {
  if [ "$1" == "1" ]; then
    PicsDirSel=`zenity --file-selection --directory --title="Choose a directory with images inside"`

    if [ "$?" != "0" ]; then
      zenity --info --ok-label="OK" --text='No directory was selected! Choose a directory and click OK.'
      SetupFun 1
    fi

    elif [ "$1" == "2" ]; then
    SleepFor=`zenity --entry --text="Set the time interval for the shuffle.\nTime is in Seconds:"`

    if [ "$?" != "0" ]; then
      zenity --info --ok-label="OK" --text='Invalid time! Please set the time in Seconds.\nExample: Set 30, for the picture to be shuffled every 30 Seconds.'
      SetupFun 2
    fi

    if (( "$SleepFor" < "5" )) || (( "$SleepFor" > "3600" )) || [ -z "$SleepFor" ]; then
      zenity --info --ok-label="OK" --text='Invalid time!\nPlease set a value between 5-3600.'
      SetupFun 2
    fi

  else
    exit 0
  fi
}
SetupFun 1
SetupFun 2

# Sync pics to file.
( find $PicsDirSel -iname "*.jpg" -or -iname "*.png" > $PicsDb; sleep 5 ) | zenity --progress --text='Creating Images Database...' --pulsate --auto-close --no-cancel

# Make sure .config/autostart directory exists
if [ ! -d "$StartItDir" ]; then
  mkdir -p $StartItDir
fi

# Set background picture options
gsettings set org.gnome.desktop.background color-shading-type "solid"
gsettings set org.gnome.desktop.background draw-background "true"
gsettings set org.gnome.desktop.background picture-opacity "100"
gsettings set org.gnome.desktop.background picture-options "scaled"
gsettings set org.gnome.desktop.background primary-color "#000000"
gsettings set org.gnome.desktop.background secondary-color "#000000"

# Write and set script file.
cat > $ScriptDest << EOF
#!/bin/bash
# A Script To Randomly Change Desktop Backgrounds.

# Vars
WeekIs=\`date +%w\`

# Check week number and resync pics to file
if [ "\$WeekIs" == "$ReScanWeek" ]; then
  find $PicsDirSel -iname "*.jpg" -or -iname "*.png" > $PicsDb
fi

while true
  do
    # Shuffle pics and set desktop backgrounds
    gsettings set org.gnome.desktop.background picture-uri "'file://\`cat $PicsDb | shuf -n 1\`'"

    sleep $SleepFor
done
EOF

chmod 755 $ScriptDest

# Write autostart desktop file.
cat > $StartItDir/$StartItFile << EOF
[Desktop Entry]
Name=RandDeskPics
Comment=Randomly change desktop pictures
Exec=$HOME/.rand-desk-pics.sh
Terminal=false
Type=Application
StartupNotify=true
MimeType=application/x-shellscript;
EOF

zenity --info --ok-label="Close" --text="Setup Has Finished\n\nThe changes will start in the next reboot\nYou may delete the Setup file now.\nEnjoy (:"
