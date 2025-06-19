#!/bin/bash
set -e

if tput setaf 1 >&/dev/null; then
    RED=$(tput setaf 1)
    GREEN=$(tput setaf 2)
    YELLOW=$(tput setaf 3)
    BLUE=$(tput setaf 4)
    BOLD=$(tput bold)
    NC=$(tput sgr0)
else
    RED=""
    GREEN=""
    YELLOW=""
    BLUE=""
    BOLD=""
    NC=""
fi

print_header() {
    echo "${BLUE}###################################################################################${NC}"
    echo "${BLUE}###${NC} ${BOLD}Vulkan UI Renderer Enabler${NC}"
    echo "${BLUE}###${NC}"
    echo "${BLUE}###${NC} ${YELLOW}1. Ensure your device is authorized by ADB.${NC}"
    echo "${BLUE}###${NC}    It must appear as 'device' in \`adb devices\`."
    echo "${BLUE}###${NC}"
    echo "${BLUE}###${NC} ${RED}2. After the phone restarts, UNLOCK THE SCREEN as soon as possible.${NC}"
    echo "${BLUE}###${NC}    Some apps require an immediate unlock to switch to Vulkan."
    echo "${BLUE}###${NC}    ADB commands also won't work until the device is unlocked."
    echo "${BLUE}###################################################################################${NC}"
    echo
}

wait_for_device() {
    echo "${YELLOW}Waiting for authorized ADB device...${NC}"
    while true; do
        state=$(adb get-state 2>/dev/null || true)
        case "$state" in
            'device')
                echo "${GREEN}Device authorized and ready.${NC}"
                break
                ;;
            'unauthorized')
                echo "${RED}Device unauthorized. Please check your phone and approve the USB debugging prompt.${NC}"
                ;;
            *)
                echo "${YELLOW}No device detected. Please connect your device via USB.${NC}"
                ;;
        esac
        sleep 3
    done
}

apply_tweaks() {

    echo "Setting HWUI renderer to vulkan"
    adb shell setprop debug.hwui.renderer skiavk

    echo "Restarting System UI..."
    adb shell am crash com.android.systemui

    echo "Forcing stop: Settings, Launcher, and AOD Service..."
    adb shell am force-stop com.android.settings
    adb shell am force-stop com.sec.android.app.launcher
    adb shell am force-stop com.samsung.android.app.aodservice

    local gboard_check
    read -p "${BOLD}Is Gboard (com.google.android.inputmethod.latin) installed? [y/n]: ${NC}" -n 1 -r gboard_check
    echo

    if [[ "$gboard_check" =~ ^[Yy]$ ]]; then
        echo "Restarting Gboard..."
        adb shell am crash com.google.android.inputmethod.latin
    else
        echo "Skipping Gboard restart."
    fi
}


print_header
read -p "${BOLD}Press [Enter] to begin the process...${NC}"

wait_for_device
echo "${YELLOW}Rebooting device now. Please be ready to unlock your screen after it restarts.${NC}"
adb reboot

wait_for_device
apply_tweaks

echo
echo "${GREEN}${BOLD}All commands executed successfully! Your device should now be using the Vulkan renderer.${NC}"

