#!/bin/sh

# Release variable
RELEASE="$(lsb_release -a 2>/dev/null)"

# Indicator Variables
UBUNTU_IND=$(echo "$RELEASE" | grep -c "Ubuntu")
POP_IND=$(echo "$RELEASE" | grep -c "Pop")
MANJARO_IND=$(whereis pamac | grep -c "pamac: /usr/bin/pamac")
ARCH_IND=$(whereis pacman | grep -c "pacman: /usr/bin/pacman")
DEBIAN_IND=$(whereis apt | grep -c "apt: /usr/bin/apt")
FLATPAK_IND=$(whereis flatpak | grep -c "flatpak: /usr/bin/flatpak")
SNAP_IND=$(whereis snap | grep -c "snap: /usr/bin/snap")   

# Distro Details
echo "Thank you for using AnarchoFerret's Update Script"
echo
echo "The script has determined the following:"
if [ $DEBIAN_IND -gt 0 ]
then
  echo "This system is Debian"
  if [ $POP_IND -gt 0 ]
  then
    echo "This system is Pop!_OS"
  fi
  if [ $UBUNTU_IND -gt 0 ]
  then
    echo "This system is Ubuntu"
  fi
elif [ $ARCH_IND -gt 0 ]
then
  echo "This system is Arch"
else
  echo "ERROR:  System cannot be determined!"
fi

echo 
echo "Current repos installed:"
if [ $DEBIAN_IND -gt 0 ]
then
  echo "APT (Advanced Package Tool)"
fi
if [ $ARCH_IND -gt 0 ]
then
  echo "pacman"
  if [ $MANJARO_IND -gt 0 ]
  then
    echo "Pamac (which will be used instead of pacman)"
  fi
fi
if [ $FLATPAK_IND -gt 0 ]
then
  echo "Flatpak"
fi
if [ $SNAP_IND -gt 0 ]
then
  echo "Snap"
fi

# If the distro is Debian
if [ $DEBIAN_IND -gt 0 ]
then
  echo
  echo "Checking for updated APT packages. Please wait..."
  STATEMENT="$(sudo apt update 2>/dev/null | grep "All packages are up to date.")"

# Upgrade existing APT packages
  if [ "$STATEMENT" = "All packages are up to date." ] # Note:  quotes are needed to denote a string
  then
    echo "No updates needed through APT."
  else
    echo "APT has updates:  "
    echo "The following prompts will require capital letters"
    read -p "Would you like to view out of date packages? [Y/N]:  " ANSWER_1
    if [ "$ANSWER_1" = "Y" ]
    then
      apt list -a --upgradable
    elif [ "$ANSWER_1" = "N" ]
    then
      echo "Upgrades hidden."
    else
      echo "User input not understood.  Defaulting to 'No' to save space."
    fi

    read -p "Would you like to update these packages? [Y/N]:  " ANSWER_2
    if [ "$ANSWER_2" = "Y" ]
    then
      sudo apt-get upgrade -y
    elif [ "$ANSWER_2" = "N" ]
    then
      echo "Update Canceled"
    else
      echo "User input not understood.  Assuming no updates wanted."
    fi
  fi
  echo "Update Complete!"

  # *Optional* Upgrade Pop!_OS Recovery Partition
  if [ $POP_IND -gt 0 ]
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

    echo

    if [ "$ARCH_UPDATES" = "" ]
    then
      echo "No updates required."

    else
      echo "There are updates."
      read -p "Would you like to view out of date packages? [Y/N]:  " ARCH_CONSENT
      if [ "$ARCH_CONSENT" = "Y" ]
      then
        sudo pacman -Qu
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

# *Optional* Upgrade Snap Packages
echo
if [ $SNAP_IND -gt 0 ]
then
  echo "Updating Snap Packages"
  sudo snap refresh
fi

if [ $FLATPAK_IND -gt 0 ]
then
  echo
  read -p "Would you like to search for and apply Flatpak app updates? [Y/N]:  " FLATPAK_CONSENT
  if [ "$FLATPAK_CONSENT" = "Y" ]
  then
    echo "Updating and upgrading.  Please wait..."
    flatpak update -y
    echo "Update Complete!"
  elif [ "$FLATPAK_CONSENT" = "N" ]
  then
    echo "Update cancelled."
  else
    echo "User input not defined.  Defaulting to 'N'."
  fi
fi
exit