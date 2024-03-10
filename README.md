# StickyDesktopPlugin

Steam Deck Persistent Desktop Plugin

This repository contains a system modification for the original Steam Deck, designed to prevent the device from defaulting back to Gaming Mode from Desktop Mode upon every system restart. It enables the Steam Deck to remember the last used mode and ensures that users who prefer starting in Desktop Mode can do so without manually switching each time the system reboots.


Features

Persistent Desktop Mode: Ensures the Steam Deck starts in Desktop Mode if that was the last used mode before the system was restarted.

Configuration File: Basic config file to customise behavior in response to use.

Sound Notifications: Utilizes system sounds for enhanced feedback. I would post the version that has the sounds I used included but I'm not sure how licensing works. I found them in usr/share/sounds. Let me know if you have any issues.


Installation

You could clone the repository but it's so lightweight I'd just download it and run the Install Script.
Follow the on-screen prompts to complete the installation.

Usage
After installation, your Steam Deck will automatically remember the last mode (Desktop or Gaming) you were in before shutdown or restart and boot into that mode.

To activate or deactivate the plugin run /install.sh


Contributing
Contributions to improve the script or add new features are welcome. If you encounter any issues or have suggestions, please open an issue or submit a pull request.

Credits
Special thanks to Reddit user kaportaci_davud for sharing the crucial commands. Without their contribution, this project would not have been possible.

License
This project is licensed under the MIT License - see the LICENSE file for details. (I think I did that right)

Disclaimer
This mod is provided as-is without any guarantees. While it has been tested to work on the Steam Deck, users should use it at their own risk. Always ensure you have backups of important data before making system modifications.
