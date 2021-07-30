#!/bin/sh
echo "Checking for new software..."
echo " "
echo "Changing to root user..."
sudo apt update
echo " "
echo "Attempting an upgrade"
sudo apt upgrade -y
echo " "
echo "Update Complete!"
echo "Leaving root to update Flatpak repo..."
echo " "
echo "Checking for Flatpak updates..."
flatpak update -y
echo " "
echo "All Updates Complete!"
echo "exiting..."
exit