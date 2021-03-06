#!/bin/sh
find_bin()
{
  local temp_var=$(whereis $1 | grep -c "/usr/bin/$1")

  if [ $temp_var -gt 0 ]
  then
    echo "1"
  else
    echo "0"
  fi
}

capitalize()
{
  echo "$1" | tr [a-z] [A-Z]
}

determine_distro()
{
  local temp_var=$(lsb_release -a 2>/dev/null | grep -c "$1")

  if [ $temp_var -gt 0 ]
  then
    echo "1"
  else
    echo "0"
  fi
}

dnf_list_updates()
{
  case $1 in
    Y)
      dnf list --upgrades
      ;;
    N)
      echo "Not showing updates."
      ;;
    *)
      echo "User input not defined.  Defaulting to 'N'."
      ;;
  esac
}

dnf_upgrade()
{
  case $1 in
    Y)
      echo "Y" | pkexec dnf upgrade
      echo "DNF updates complete!"
      ;;
    N)
      echo "Not showing updates."
      ;;
    *)
      echo "User input not defined.  Defaulting to 'N'."
      ;;
  esac
}

update_debian()
{
  case $1 in
    Y)
      pkexec apt-get dist-upgrade -y
      ;;
    N)
      echo "Update Canceled"
      ;;
    *)
      echo "User input not understood.  Assuming no updates wanted."
      ;;
  esac
}

list_debian_updates()
{
  case $1 in
    Y)
      apt list -a --upgradable
      ;;
    N)
      echo "Upgrades hidden."
      ;;
    *)
      echo "User input not understood.  Defaulting to 'No' to save space."
      ;;
  esac
}

pop_recovery_upgrade()
{
  case $1 in
    Y)
      if [ -d "/recovery" ] # If the recovery folder is found
      then
        # Check and apply upgrades
        pop_check="$(pkexec pop-upgrade recovery upgrade from-release | grep -c "recovery partition was not found")"
    
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
      ;;
    N)
      echo "Pop!_OS recovery partition not updated."
      ;;
    *)
      echo "User input not understood.  Recovery partition not updated."
      ;;
  esac
}

snap_update()
{
  case $1 in
    Y)
      pkexec snap refresh
      echo "Snap updates complete!"
      ;;
    N)
      echo "Update cancelled."
      ;;
    *)
      echo "User input not defined.  Defaulting to 'N'."
      ;;
  esac
}

flatpak_update()
{
  case $1 in
    Y)
      flatpak update -y
      echo "Flatpak updates complete!"
      ;;
    N)
      echo "Update cancelled."
      ;;
    *)
      echo "User input not defined.  Defaulting to 'N'."
      ;;
  esac
}

automated_install()
{
  echo "Thank you for using AnarchoFerret's Update Script"

  if [ $(find_bin apt) -gt 0 ]
  then
    local deb_temp="$(pkexec apt update 2>/dev/null | grep "All packages are up to date.")"
    if [ "$deb_temp" = "All packages are up to date." ]
    then
      echo "No updates needed through APT."
    else
      update_debian Y 
    fi 

    if [ $(determine_distro Pop) -gt 0 ]
    then
      pop_recovery_upgrade Y 
    fi
  elif [ $(find_bin pacman) -gt 0 ]
  then
    if [ $(find_bin pamac) -gt 0 ]
    then
      pamac update 
    else
      local arch_temp="$(pkexec pacman -Qu)"
      if [ "$ARCH_UPDATES" = "" ]
      then
        echo "No updates through pacman."
      else
        pkexec pacman -Syu
      fi
    fi
  elif [ $(find_bin dnf) -gt 0 ]
  then
    local RHEL_temp=$(echo "N" | pkexec dnf upgrade | grep -c "Total download size")

    if [ $DNF_UPDATES -gt 0 ]
    then
      echo "Y" | pkexec dnf upgrade
    else
      echo "No updates through DNF."
    fi
  fi

  if [ $(find_bin snap) -gt 0 ]
  then
    pkexec snap refresh
  fi

  if [ $(find_bin flatpak) -gt 0 ]
  then
    flatpak_update Y 
  fi

  echo "All repos updated!"
}

# Debugging Arguments
DEBUG=0

if [ "$1" = "-h" ]
then
  echo "Available Commands:"
  echo "-h:  Show help"
  echo "-auto-upgrade:  perform a relatively silent update."
  echo "-d:  Turn on debugging"
  exit
elif [ "$1" = "-d" ]
then
  echo "Debugging enabled"
  DEBUG=1
elif [ "$1" = "-auto-upgrade" ]
then
  automated_install
  exit
fi


# Distro Details
echo "Thank you for using AnarchoFerret's Update Script"
echo
echo "The script has determined the following:"
if [ $(find_bin apt) -gt 0 ]
then
  echo "This system is Debian"
  if [ $(determine_distro Pop) -gt 0 ]
  then
    echo "The Distro is Pop!_OS"
  fi
  if [ $(determine_distro Ubuntu) -gt 0 ]
  then
    echo "This Distro is Ubuntu"
  fi
elif [ $(find_bin pacman) -gt 0 ]
then
  echo "This system is Arch"
elif [ $(find_bin dnf) -gt 0 ]
then
  echo "This is Red Hat / Fedora"
else
  echo "ERROR:  System cannot be determined!"
fi

echo 
echo "Current repos installed:"
if [ $(find_bin apt) -gt 0 ]
then
  echo "APT (Advanced Package Tool)"
fi
if [ $(find_bin pacman) -gt 0 ]
then
  echo "pacman"
  if [ $(find_bin pamac) -gt 0 ]
  then
    echo "Pamac (which will be used instead of pacman)"
  fi
fi
if [ $(find_bin dnf) -gt 0 ]
then
  echo "DNF (Dandified YUM)"
fi
if [ $(find_bin flatpak) -gt 0 ]
then
  echo "Flatpak"
fi
if [ $(find_bin snap) -gt 0 ]
then
  echo "Snap"
fi

# If the distro is Debian
if [ $(find_bin apt) -gt 0 ]
then
  echo
  echo "Checking for updated APT packages. Please wait..."
  STATEMENT="$(pkexec apt update 2>/dev/null | grep "All packages are up to date.")"

  # Upgrade existing APT packages
  if [ "$STATEMENT" = "All packages are up to date." ] # Note:  quotes are needed to denote a string
  then
    echo "No updates needed through APT."
  else
    echo "APT has updates:"
    read -p "Would you like to view out of date packages? [Y/N]:  " ANSWER_1
    ANSWER_1=$(capitalize $ANSWER_1)
    list_debian_updates $ANSWER_1

    read -p "Would you like to update these packages? [Y/N]:  " ANSWER_2
    ANSWER_2=$(capitalize $ANSWER_2)
    update_debian $ANSWER_2 
    
  fi
  echo "Updates through APT Complete."

  # *Optional* Upgrade Pop!_OS Recovery Partition
  if [ $(determine_distro Pop) -gt 0 ]
  then
    echo
    read -p "Pop!_OS found on system.  Attempt to update recovery partition?  [Y/N]:  " POP_CONSENT
    POP_CONSENT=$(capitalize $POP_CONSENT)
    pop_recovery_upgrade $POP_CONSENT
  fi

# Determine if Distro is Arch
elif [ $(find_bin pacman) -gt 0 ]
then
  
  # First check for Manjaro | Use Pamac update
  if [ $(find_bin pamac) -gt 0 ]
  then
    echo
    echo "Running Manjaro Update script.  This will update both"
    echo "your AUR (yay) and Arch Repos (pacman)."
    pamac update

  else # Vanilla Arch update
    ARCH_UPDATES="$(pkexec pacman -Qu)"

    echo

    if [ "$ARCH_UPDATES" = "" ]
    then
      echo "No updates required."

    else
      echo "There are updates."
      read -p "Would you like to view out of date packages? [Y/N]:  " ARCH_CONSENT
      ARCH_CONSENT=$(capitalize $ARCH_CONSENT)
      if [ "$ARCH_CONSENT" = "Y" ]
      then
        pkexec pacman -Qu
      elif [ "$ARCH_CONSENT" = "N" ]
      then
        echo "Not showing updates."
      else
        echo "ERROR:  User input undefined!  Defaulting to 'N'."
      fi

      read -p "Would you like to download and install updates? [Y/N]:  " ARCH_CONSENT_UPDATE
      ARCH_CONSENT_UPDATE=$(capitalize $ARCH_CONSENT_UPDATE)
      if [ "$ARCH_CONSENT_UPDATE" = "Y" ]
      then
       echo "Downloading and applying updates.  Please wait..."
       pkexec pacman -Syu > /dev/null
       echo "Updates complete!"
      elif [ "$ARCH_CONSENT_UPDATE" = "N" ]
      then
        echo "Not applying updates."
      else
        echo "ERROR:  User input undefined!  Defaulting to 'N'."
      fi
    fi
  fi

# Determine if Distro is RHEL
elif [ $(find_bin dnf) -gt 0 ]
then
  echo 
  echo "Checking for updates through DNF.  Please wait..."
  DNF_UPDATES=$(echo "N" | pkexec dnf upgrade | grep -c "Total download size")

  if [ $DNF_UPDATES -gt 0 ]
  then
    echo "Updates have been found."
    read -p "Would you like to view out of date packages? [Y/N]:  " RHEL_CONSENT_1
    RHEL_CONSENT_1=$(capitalize $RHEL_CONSENT_1)
    dnf_list_updates $RHEL_CONSENT_1
    
    read -p "Would you like to update out of date packages? [Y/N]:  " RHEL_CONSENT_2
    RHEL_CONSENT_2=$(capitalize $RHEL_CONSENT_2)
    dnf_upgrade $RHEL_CONSENT_2
  else
    echo "No updates at this time."
  fi
fi

# *Optional* Upgrade Snap Packages
if [ $(find_bin snap) -gt 0 ]
then
  echo
  read -p "Would you like to update snap? [Y/N]:  " SNAP_CONSENT
  SNAP_CONSENT=$(capitalize $SNAP_CONSENT)
  snap_update $SNAP_CONSENT
fi

# *Optional* Upgrade Flatpak Packages
if [ $(find_bin flatpak) -gt 0 ]
then
  echo
  read -p "Would you like to search for and apply Flatpak app updates? [Y/N]:  " FLATPAK_CONSENT
  echo "Updating and upgrading.  Please wait..."
  FLATPAK_CONSENT=$(capitalize $FLATPAK_CONSENT)
  flatpak_update $FLATPAK_CONSENT
fi
exit