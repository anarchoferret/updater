#!/bin/sh
echo "Checking for new software..."
echo " "
echo "Changing to root user..."

# update apt repos
echo " "
echo "Checking if Debian..."
#[ -d "/usr/lib/apt" ] && echo "APT exists"
if [ -d "/usr/lib/apt" ]
then
  echo "This system is using Debian!"
  echo "Checking for updated apt packages..."
  sudo apt update > log.txt
  statement="$(grep "All packages are up to date."  log.txt)"

# upgrade existing packages
  echo " "
  if [ "$statement" = "All packages are up to date." ] # Note:  quotes are needed to denote a string
  then
    echo "No updates needed through apt."
  else
    echo "APT has updates; downloading and installing..."
      sudo apt upgrade -y
  fi
  echo "Update Complete!"

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
fi

# pop-upgrade recovery upgrade from-release
  echo " "
  echo "Update Complete!"
  echo "Leaving root to update Flatpak repo..."

# Update Flatpak packages
if [ -d "/usr/bin/flatpak" ]
then
  echo " "
  echo "Checking for Flatpak updates..."
  flatpak update -y
  echo " "
  echo "All Updates Complete!"
fi

# Exit
echo "exiting..."
exit
