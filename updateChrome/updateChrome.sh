#!/bin/zsh

# Set constants
temp_dir="/Users/Shared/"
chrome_download_url="aURL"
chrome_file="$temp_dir/googlechrome.pkg"
install_log="/Users/Shared/Company/logs/chrome_updates.txt"
logo_url="https://aURL.com/district_logo_200_pixel.png"
logo_file="/Users/Shared/Company/logo/district_logo_200_pixel.png"
jHelper="/Library/Application Support/JAMF/bin/jamfHelper.app/Contents/MacOS/jamfHelper"
title="Software Update Available"
heading="Google Chrome Update"
description_template="A new version of Google Chrome (%s) is available. Would you like to update now?"
icon="$logo_file"
button1="Update"
button2="Later"

# Define the function to fetch the latest Google Chrome version from the internet.
fetch_latest_chrome_version() {
    local url="https://chromereleases.googleblog.com/search?max-results=10"
    local webpage_content=$(curl --compressed -s "$url")

    # Process the content to find the version number.
    local version=$(echo "$webpage_content" | awk '
    BEGIN { inSection=0; version="" }
    /Stable Channel Update for Desktop/ { inSection=1 }
    inSection && /updated to/ {
        sub(/.*updated to /, "", $0)
        sub(/ .*/, "", $0)
        if (index($0, "/") > 0) {
            split($0, parts, "/")
            version = parts[2]  # Focus on the part after the slash
        } else {
            version = $0
        }
        print version
        exit
    }
    END { if (version == "") print "Could not find a specific Stable Channel Update for Desktop with a version number." }
    ')

    echo "$version"
}

# Define the function to check the local version of an application.
check_app_version() {
    if [ -z "$1" ]; then
        echo "error: No application name provided"
        return 1
    fi

    local app_name="$1"
    local app_path="/Applications/$app_name.app"

    if [ -d "$app_path" ]; then
        local version=$(mdls -name kMDItemVersion "$app_path" | awk -F'"' '{print $2}')
        if [ -n "$version" ]; then
            echo "$version"
        else
            echo "error: Version not found"
            return 2
        fi
    else
        echo "error: $app_name is not installed"
        return 3
    fi
}

verify_signatureGoogleChrome() {
    local file="$1"
    if pkgutil --check-signature "$file" | grep -q "Google LLC"; then
        echo "$(date '+%Y-%m-%d %H:%M:%S') - Signature verification successfully." >> "$install_log"
        echo "true"
    else
        echo "$(date '+%Y-%m-%d %H:%M:%S') - Signature verification failed." >> "$install_log"
        echo "false"
    fi
}

prompt_user() {
    local message=$(printf "$description_template" "$latest_version")
    "$jHelper" -windowType utility -title "$title" -heading "$heading" -description "$message" -icon "$icon" -button1 "$button1" -button2 "$button2"
}

handle_chrome_running() {
    if pgrep "Google Chrome"; then
        osascript -e 'tell application "Google Chrome" to quit'
        sleep 5
        killall "Google Chrome" 2>/dev/null
        sleep 2
    fi
}

install_chrome() {
    installer -pkg "$chrome_file" -target /
}

# Main logic starts here
latest_version=$(fetch_latest_chrome_version)
local_version=$(check_app_version "Google Chrome")

if [[ "$latest_version" == "$local_version" ]]; then
    echo "$(date '+%Y-%m-%d %H:%M:%S') - Google Chrome already update-to-date." >> "$install_log"
    exit 0
fi

# Ensure logo file exists
[[ ! -f "$logo_file" ]] && curl "$logo_url" --output "$logo_file"

# Download or verify existing file
if [[ ! -f "$chrome_file" ]]; then
    curl -L "$chrome_download_url" -o "$chrome_file"
fi

signature_check=$(verify_signatureGoogleChrome "$chrome_file")
if [[ $signature_check != "true" ]]; then
    echo "Signature verification failed. Exiting." >> "$install_log"
    rm $chrome_file
    exit 1
fi

userChoice=$(prompt_user)
if [[ $userChoice -eq 0 ]]; then
    handle_chrome_running
    install_chrome && echo "$(date '+%Y-%m-%d %H:%M:%S') - Google Chrome installed successfully." >> "$install_log"
    say "Google Chrome Update Complete"
else
    echo "$(date '+%Y-%m-%d %H:%M:%S') - User chose not to update Google Chrome." >> "$install_log"
fi
