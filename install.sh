#!/bin/bash

# Fix error where it will run from .desktop even if not installed

# Locates itself
# Handles symbolic links and should work in most environments
here=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
me="$here/install.sh"
target="$HOME" # "Where am I going?"
utils="$here/utils" # Util directory
config_file="StickyDP" # Configuration file
config="$target/.config/$config_file"
startup_file="sticky-desktop-plugin.sh.desktop"
logstr="" # Initialises the log buffer

## Support Functions ##

# Function to check / set up resources
initialise() {
    log "initialising"
    handle_config_file read
    handle_config_file writ "app_file=$me"

    # Update autostart path to current location, in case plugin file is moved
    NewExecPath="$me from_startup"
    if [[ -f "$target/.config/autostart/$startup_file" ]]; then
        sed -i "s|^Exec=.*|Exec=$NewExecPath|" "$target/.config/autostart/$startup_file" && \
        grep -q "Exec=$NewExecPath" "$target/.config/autostart/$startup_file" && \
        log "exec path updated to $NewExecPath" || \
        error "Failed to update Exec path in $target/.config/autostart/$startup_file"
    fi

    # Create fresh error log if none exists
    if [[ ! -s "$utils/Log.txt" ]]; then
        echo "[ Log ]" > "$utils/Log.txt"
        log "created Log.txt"
    fi
    log "initialised"
}

# Print message to terminal and append to log buffer
log() {
    echo "[Debug] $1"
    logstr+="${1}"$'\n'
}

# Main function to check and handle the config file
handle_config_file() {
    log "$1ing config"

    # Read and apply settings from the config file
    case $1 in
        read)
            # Check if the config file exists
            if [[ ! -f "$config" ]]; then
                log "no config file found"
                echo "[ Sticky Desktop Plugin Config ]" > "$config"
                echo "app_file=" >> "$config"
                if [[ ! -f "$target/.config/autostart/$startup_file" ]]; then
                    echo "Active=false" >> "$config"
                else
                    log "startup file found in $target/.config/autostart"
                    echo "Active=true" >> "$config"
                fi
                echo "QuickSwap=false" >> "$config"
                echo "FirstTimeMsg=unseen" >> "$config"
                echo "FirstReturnMsg=unseen" >> "$config"
                log "created default config file at $config"
            else
                log "config file exists at $config"

            fi
            # Use a while loop without a pipeline to avoid subshell
            while IFS='=' read -r key value; do
                if [[ $key =~ ^[[:alnum:]_]+$ ]]; then
                    declare -g "$key=$value"
                    log "$key=$value"
                else
                    error "$key not a valid key"
                fi
            done < <(grep '=' "$config")  # Redirect grep output to the while loop
            log "config read"
            ;;
        writ)
            # Takes $2 and updates key=value in the config file
            sed -i "s|^\(${2%%=*}\)=.*|\1=${2#*=}|" "$config"
            log "config updated: $2"
            ;;
        *)
            ;;
    esac
}

# Function to handle errors and log them
error() {
    error_message="$(date +"%Y-%m-%d %H:%M:%S") - Error: $1" # Glue timestamp to error message
    log "$error_message"
    log "ALL OPERATIONS TERMINATED"
    log "LOG END" # Add error to log string

    play_sound "/usr/share/sounds/Oxygen-Im-Error-On-Connection.ogg" &
    send "msgbox" "$logstr"
    echo "$logstr" >> "$utils/Log.txt" # Append log buffer to log file
    exit 1

}

send() {
    if [[ $1 == "push" ]] ; then
        play_sound "/usr/share/sounds/Oxygen-Window-Maximize.ogg"
        notify-send --app-name "Sticky Desktop Plugin" "$2"
    else
        local dialogType=$1
        local message=$2
        shift 2 # Shift past the first two arguments as they are already consumed
        kdialog --title "Sticky Desktop Plugin" --"$dialogType" "$message" "$@" # 3 4 = yes button label. 5 6 = no button label. 6 7 = cancel button label.
        return $?
    fi
}

# Function to play a sound and check for errors
play_sound() {
    local sound_file="$1"
    if ! paplay "$sound_file" &>/dev/null; then
        log "Failed to play sound: $sound_file"
    fi
}

# File operations and error handling
filer() {
    log "filer activated"
    declare -A command_strings=( [cp]="copy" [mv]="move" [rm]="delete" ) # Creates a lookup table

    # Construct command based on the operation type
    if [[ $1 == "rm" ]]; then
        command_to_run="rm \"$2\"" # rm only needs the file to be removed
        error_message="${command_strings[$1]} $2"
    else
        command_to_run="$1 \"$2\" \"$3\"" # cp and mv need source and destination
        error_message="${command_strings[$1]} $2 to $3"
    fi

    # Execute the command
    eval "$command_to_run" || error "Failed to $error_message"
}


## Primary Functions ##

# Function to handle installing Sticky Desktop plugin
installer() {
    # Interactive confirmation for installing
    log "install mode"
    play_sound "/usr/share/sounds/Oxygen-Im-User-Auth.ogg" &
    if send "yesno" \
"Set Steam Deck to automatically boot in the last used mode?\n\n\
This will:\n\
+ Create the config file '$config_file' in $target/.config/.\n\
+ Create the file '$startup_file' in $target/.config/autostart/.\n\
+ Swap the 'Return to Gaming Mode' shortcut with one that works with this plugin.\n\n\
- Can't automatically restart to Desktop Mode from Gaming Mode, sorryy.\n\n\
Run 'install.sh' to return system to default and remove all traces of StickyDP.\n\
(please let me know if I missed anything)"; then

        handle_config_file writ "Active=true" # Update config file to reflect activated status
        # Copy and swap files
        filer cp "$utils/$startup_file" "$target/.config/autostart/"
        filer mv "$target/Desktop/Return to Gaming Mode.desktop" "$utils/Return to Gaming Mode(OG).desktop"
        filer cp "$utils/Return to Gaming Mode(SDP).desktop" "$target/Desktop/Return to Gaming Mode.desktop"

        log "all items relocated successfully"


        $me from_startup

    else
        filer rm "$target/.config/$config_file"
        send "push" "Nothing changed."
        exit 0
    fi
}

# Function to handle deactivating Sticky Desktop plugin
uninstaller(){
    # Interactive confirmation for deactivating
    log "uninstall mode"
    play_sound "/usr/share/sounds/Oxygen-Window-All-Desktops-Not.ogg" &
    if send "yesno" \
    "Uninstall Sticky Desktop plugin?"; then

        # Remove and restore files to their original state with error checking
        filer rm "$target/.config/autostart/$startup_file"
        filer rm "$target/Desktop/Return to Gaming Mode.desktop"
        filer mv "$utils/Return to Gaming Mode(OG).desktop" "$target/Desktop/Return to Gaming Mode.desktop"
        filer rm "$target/.config/$config_file"

        log "all things back in their rightful place"

        play_sound "/usr/share/sounds/Oxygen-K3B-Finish-Success.ogg" &
        send "msgbox" \
"Thank you for using StarGooseLabs' Steam Deck plugin. \
If you have a moment, I'd appreciate any feedback or \
insights you might want to share. Your input is invaluable \
for future improvements and fuelling other innovations.\n\n\
If you ever want this functionality again or wish \
to explore more, I'm just a click away.\n\n\
Reddit: https://www.reddit.com/user/GeneralGoosery\n\
Ko-Fi: https://ko-fi.com/generalgoosery\n\n\
Thank you for being part of my coding journey. \
Your engagement is always appreciated!"

    else
        send "push" "Nothing changed."
        exit 0
    fi
}

# Set Steam Deck to boot in Desktop Mode on the next restart.
desktop-mode() {
    send "push" "Startup Mode: Desktop"
    steamos-session-select plasma-persistent

    log "$FirstTimeMsg"
    if [[ $FirstTimeMsg == "unseen" ]]; then
        send "push" "Restart for +10 satisfaction."
        handle_config_file writ "FirstTimeMsg=ready"

    elif [[ $FirstTimeMsg == "ready" ]]; then
        # Success message with support links
        play_sound "/usr/share/sounds/Oxygen-Sys-Log-In-Long.ogg" &
        send "msgbox" \
"StarGooseLabs is proud to bring you a dash of convenience. \
Feel the difference!\n\n\
If you find this helpful, please leave a nice message \
or you can show your support with a tip:\n\n\
Reddit: https://www.reddit.com/user/GeneralGoosery\n\
Ko-Fi: https://ko-fi.com/generalgoosery\n\n\
Your support and feedback fuel my continued experimentation. Thank you!\n\n\
~ Very special thanks to Reddit user kaportaci_davud ~\n\
For sharing the crucial system commands. Without them, none \
of this plugin would have worked, and I might never \
have dedicated this time to learning bash* scripting.\n\n\
*bashing my head against my keyboard"

        handle_config_file writ "FirstTimeMsg=seen"
    fi
}

# Switch to Gaming Mode
gaming-mode() {
    log "Gaming Mode"
    if [[ "$QuickSwap" == "true" ]] ; then
        log "QuickSwap activated"
        send "push" "Switching to Gaming Mode"
        steamos-session-select gamescope
    else
        play_sound "/usr/share/sounds/Oxygen-Sys-App-Positive.ogg" &

        # Get user input
        send "yesnocancel" "Switch to Gaming Mode?" \
            --yes-label "Let's go!" \
            --no-label "Yes (don't ask again)" \
            --cancel-label "Cancel"
        user_input=$?
        log "user input: $user_input"

        # First time message
        if [[ $user_input == 0 ]] || [[ $user_input == 1 ]]; then # If user doesn't cancel
            log "$FirstReturnMsg"
            if [[ "$FirstReturnMsg" == "unseen" ]]; then
                send "msgbox" \
"This is as far as I go, I have no way to pull you back here \
on a restart. Worry not, I'll keep doing my thing once you \
return to Desktop Mode.\n\n\
If you ever want to disable me just run 'install.sh'.\n\
If you chose (don't ask again) you'll need to reinstall to reset it."

                handle_config_file writ "FirstReturnMsg=seen"
            fi
        fi

        # Checks user choice
        if [[ $user_input == 0 ]]; then # "Yes" selected
            send "push" "Switching to Gaming Mode"
            steamos-session-select gamescope

        elif [[ $user_input == 1 ]]; then # "Yes, don't ask again" selected
            log "QuickSwap mode selected"
            handle_config_file writ "QuickSwap=true" # Saves QuickSwap mode to config
            send "push" "Switching to Gaming Mode"
            send "push" "It's been a real slice"
            steamos-session-select gamescope

        else
            send "push" "Staying in Desktop Mode"
        fi
    fi
}



# Body

initialise
case "$1" in
    from_startup)
        log "Called from startup"
        if [[ $Active != "true" ]]; then
            error "install plugin first"
        else
            desktop-mode
        fi
        ;;
    from_desktop)
        log "Called from desktop shortcut"
        if [[ $Active != "true" ]]; then
            error "install plugin first"
        else
            gaming-mode
        fi
        ;;
    from_empty)
        send "msgbox" "Boing!"
        ;;
    *)
        log "Installer Mode"

        # Debugging: Print the current value of Active
        log "Active is currently set to: $Active"

        if [[ "$Active" == "false" ]] ; then
            installer
        elif [[ "$Active" == "true" ]] ; then
            uninstaller
        else
            error "Active variable is set to an unexpected value: $Active"
        fi
        ;;
esac


### "To the curious eyes exploring this code, your interest is appreciated!
### This journey involved a couple of all-nighters, a lot of ChatGPT troubleshooting, and walking
### away from it all for a month. After all that though, going from zero scripting experience to
### this, I'm very happy with the result and the all things I've learned.
### Feel free to reach out with your thoughts or just to share a coding story. Happy scripting!" - GeneralGoosery, StarGooseLabs
