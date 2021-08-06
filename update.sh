#!/bin/sh
echo "Checking for new software..."

# update apt repos
echo " "
#[ -d "/usr/lib/apt" ] && echo "APT exists"
if [ -d "/usr/lib/apt" ]
then
  echo "This system is using Debian!"
  echo "Checking for updated apt packages..."
  sudo apt update > log.txt 2>/dev/null
  statement="$(grep "All packages are up to date."  log.txt)"

# upgrade existing packages
  echo " "
  echo "$statement"
  if [ "$statement" = "All packages are up to date." ] # Note:  quotes are needed to denote a string
  then
    echo "No updates needed through apt."
  else
    echo "APT has updates:  "
    read -p "Would you like to update these packages? [Y/N]:  " answer1
    if [ "$answer1" = "Y"]
    then
      apt list --upgradable
    elif [ "$answer1" = "N" ]
    then
      echo "Upgrades hidden."
    else
      echo "User input not understood.  Defaulting to 'No' to save space."
    fi

    read -p "Would you like to update these packages? [Y/N]:  " answer2
    if [ "$answer2" = "Y" ]
    then
      sudo apt-get upgrade -y > /dev/null
    elif [ "$answer2" = "N" ]
    then
      echo "Update Canceled"
    else
      echo "User input not understood.  Assuming no updates wanted."
    fi
  fi
  echo "Update Complete!"
  rm log.txt 

# Optional:  update pop os recovery partition
  echo " "
  echo "Checking if Pop!_OS Recovery partition is found..."
  if [ -d "/recovery" ]
  then
    pop-upgrade recovery upgrade from-release > pop-check.txt
    pop_check="$(grep -c "recovery partition was not found"  pop-check.txt)"
    if [ "$pop_check" = "1" ]
    then
      echo "Pop!_OS Recovery partition not in use"
    else
      echo "Updating Pop!_OS Recovery partition"
      pop-upgrade recovery upgrade from-release
    fi
  else
    echo "Pop!_OS recovery partition not found!"
  fi
  rm pop-check.txt 
fi
echo "Update Complete!"

# Update Flatpak packages
if [ -d "/usr/share/flatpak" ]
then
  echo " "
  echo "Checking for Flatpak updates..."
  flatpak update -y > flatpaklog.txt
  flatcheck="$(grep "Nothing to do."  flatpaklog.txt)"
  if [ "$flatcheck" = "Nothing to do." ]
  then
    echo "No flatpak updates."
  else
    echo "Flatpak apps updated!"
  fi
  rm flatpaklog.txt
  echo " "
fi

# Exit
echo "exiting..."
exit
