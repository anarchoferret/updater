#!/bin/sh

# Release variable
RELEASE="$(lsb_release -a 2>/dev/null)"

# Distro Indicator Variables
POP=$(echo "$RELEASE" | grep -c "Pop")
MANJARO=$(echo "$RELEASE" | grep -c "Manjaro")
UBUNTU=$(echo "$RELEASE" | grep -c "Ubuntu")
UBUNTU_IND=0
POP_IND=0
MANJARO_IND=0
ARCH_IND=0
DEBIAN_IND=0
FLATPAK_TEST=$(whereis flatpak | grep -c "flatpak: /usr/bin/flatpak /usr/include/flatpak /usr/share/flatpak /usr/share/man/man1/flatpak.1.gz")

# Determine the Distro
if [ $POP -gt 0 ]
then
  echo "This system is Pop!_OS"
  POP_IND=1;
  DEBIAN_IND=1
elif [ $MANJARO -gt 0 ]
then
  echo "This system is Manjaro"
  MANJARO_IND=1
  ARCH_IND=1
elif [ $UBUNTU -gt 0 ]
then 
  echo "This system is Ubuntu"
  UBUNTU_IND=1
  DEBIAN_IND=1
else
  echo "System could not be determined!"
  echo "Is your distro based off of 'Debian' or"
  read -p "Arch? [Debian/Arch]:  " SYSTEM_INQ

  if [ "$SYSTEM_INQ" = "Arch"]
  then
    ARCH_IND=1
    echo "System registered as Arch"
  elif [ "$SYSTEM_INQ" = "Debian" ]
  then
    DEBIAN_IND=1
    echo "System registered as Debian"
  else
    echo "Answer was neither 'Debian' or 'Arch'."
    echo "WARNING:  Limited functionality.  Flatpak updates only."
  fi 
fi

# If the distro is Debian
if [ $DEBIAN_IND -gt 0 ]
then
  echo
  echo "Checking for updated APT packages. Please wait..."
  statement="$(sudo apt update 2>/dev/null | grep "All packages are up to date.")"

# Upgrade existing APT packages
  if [ "$statement" = "All packages are up to date." ] # Note:  quotes are needed to denote a string
  then
    echo "No updates needed through APT."
  else
    echo "APT has updates:  "
    echo "The following prompts will require capital letters"
    read -p "Would you like to view out of date packages? [Y/N]:  " answer1
    if [ "$answer1" = "Y" ]
    then
      apt list -a --upgradable
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

  # *Optional* Upgrade Ubuntu Snap Packages
  if [ $UBUNTU_IND -gt 0 ]
  then
    echo "Updating Snap Packages"
    sudo snap refresh

  # *Optional* Upgrade Pop!_OS Recovery Partition
  elif [ $POP_IND -gt 0 ]
  then
    echo
    echo "Pop!_OS found on system.  Attempting to update recovery partition..."

    if [ -d "/recovery" ] # If the recovery folder is found
    then
      # Check and apply upgrades
      pop_check="$(pop-upgrade recovery upgrade from-release | grep -c "recovery partition was not found")"
    
      # Interpret the answer for the user
      if [ "$pop_check" = "1" ]
      then
        echo "Pop!_OS Recovery partition not in use"
      else
        echo "Found recovery parition.  Update applied, if needed."
      fi

    else # If the recovery folder is not found
      echo "Pop!_OS recovery partition not found!"
    fi
  fi

# Determine if Distro is Arch
elif [ $ARCH_IND -gt 0 ]
then
  
  # First check for Manjaro | Use Pamac update
  if [ $MANJARO_IND -gt 0 ]
  then
    echo
    echo "Running Manjaro Update script.  This will update both"
    echo "your AUR (yay) and Arch Repos (pacman)."
    pamac update

  else # Vanilla Arch update
    ARCH_UPDATES="$(sudo pacman -Qu)"

    if [ "$ARCH_UPDATES" = "" ]
    then
      echo "No updates required."

    else
      echo "There are updates."
      read -p "Would you like to view out of date packages? [Y/N]:  " ARCH_CONSENT
      if [ "$ARCH_CONSENT" = "Y" ]
      then
        echo "$ARCH_UPDATES"
      elif [ "$ARCH_CONSENT" = "N" ]
      then
        echo "Not showing updates."
      else
        echo "ERROR:  User input undefined!  Defaulting to 'N'."
      fi

      read -p "Would you like to download and install updates? [Y/N]:  " ARCH_CONSENT_UPDATE
      if [ "$ARCH_CONSENT_UPDATE" = "Y" ]
      then
       echo "Downloading and applying updates.  Please wait..."
       sudo pacman -Syu > /dev/null
       echo "Updates complete!"
      elif [ "$ARCH_CONSENT_UPDATE" = "N" ]
      then
        echo "Not applying updates."
      else
        echo "ERROR:  User input undefined!  Defaulting to 'N'."
      fi
    fi
  fi
fi 

if [ $FLATPAK_TEST -gt 0 ]
then
    echo
    echo "Flatpak is installed!"
    read -p "Would you like to update and upgrade? [Y/N]:  " FLATPAK_CONSENT
    if [ "$FLATPAK_CONSENT" = "Y" ]
    then
      echo "Updating and upgrading.  Please wait..."
      flatpak update -y > /dev/null
      echo "Update Complete!"
    elif [ "$FLATPAK_CONSENT" = "N" ]
    then
      echo "Update cancelled."
    else
      echo "User input not defined.  Defaulting to 'N'."
    fi

else
    echo "Flatpak is not installed."
    echo "To install Flatpak, please enter the following command:"

    if [ $DEBIAN_IND = 1 ]
    then
      echo "sudo apt install flatpak && flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo"
      echo "..."
      echo "then reboot!"
    elif [ $ARCH_IND = 1 ]
    then
      echo "sudo pacman -S flatpak && && flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo"
      echo "..."
      echo "then reboot!"
    else
      echo "Error:  System Unknown!"
    fi
fi
exit
