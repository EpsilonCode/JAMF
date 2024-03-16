#!/bin/zsh

jHelper="/Library/Application Support/JAMF/bin/jamfHelper.app/Contents/MacOS/jamfHelper"
title="Package Installation"
heading="New Package Available"
description="A new package is available for installation. Would you like to install it now?"
icon="jhelper-example-icon.png"  # Custom icon path
button1="Install"
button2="Later"

# Function to install package
install_package() {
    echo "Attempting to install the package..."
    # Replace 'package_name' with the actual name of the package you want to install
}

# Display the prompt using jamfHelper
userChoice=$("$jHelper" -windowType utility -title "$title" -heading "$heading" -description "$description" -icon "$icon" -button1 "$button1" -button2 "$button2" -defaultButton 1 -cancelButton 2)

# Process the user's choice
case $userChoice in
    0) # User clicked "Install"
        install_package
        ;;
    2) # User clicked "Later"
        echo "You have chosen to postpone the installation."
        # You can add logic here to handle the postponement.
        ;;
    *) # Any other response (including closing the window)
        echo "Installation postponed."
        ;;
esac
