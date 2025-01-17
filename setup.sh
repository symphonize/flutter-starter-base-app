#!/bin/bash

# Version:

# Path to the project directory
PROJECT_PATH="$(pwd)"

# Default build mode for the Flutter project
ENVIRONMENT="dev"

# Configuration file in the repository
CONFIG_FILE="fvm_config.json"

# Get the terminal width
TERMINAL_WIDTH=$(tput cols)

# Separator line based on the terminal width
SEPARATOR=$(printf '%*s' "$TERMINAL_WIDTH" '' | tr ' ' '═')

# Process the input arguments to extract dev/prod/staging and handle the rest: Array to store the remaining arguments
processed_args=()

on_auto_mode=false

# Function to update the separator line whenever the terminal width changes
update_separator() { SEPARATOR=$(printf '%*s' "$(tput cols)" '' | tr ' ' '═'); }

# Function to update the terminal width variable
update_width() { TERMINAL_WIDTH=$(tput cols); }

# Function to log informational messages in white
log_white() { echo -e "\033[37m$1\033[0m"; }

# Function to log informational messages in blue
log_blue() { echo -e "\033[34m$1\033[0m"; }

# Function to log success messages in green
log_green() { echo -e "\033[32m$1\033[0m"; }

# Function to log warning messages in yellow
log_yellow() { echo -e "\033[33m$1\033[0m"; }

# Function to log error messages in red
log_red() { echo -e "\033[31m$1\033[0m"; }

# Function to log bold white messages
log_bold_white() { echo -e "\033[1;37m$1\033[0m"; }

# Function to log bold blue messages
log_bold_blue() { echo -e "\033[1;34m$1\033[0m"; }

# Function to log bold green messages
log_bold_green() { echo -e "\033[1;32m$1\033[0m"; }

# Function to log bold yellow messages
log_bold_yellow() { echo -e "\033[1;33m$1\033[0m"; }

# Function to log bold red messages
log_bold_red() { echo -e "\033[1;31m$1\033[0m"; }

# Function to log informational messages in cyan
log_cyan() { echo -e "\033[36m$1\033[0m"; }

# Function to log informational messages in magenta
log_magenta() { echo -e "\033[35m$1\033[0m"; }

# Function to log bold cyan messages
log_bold_cyan() { echo -e "\033[1;36m$1\033[0m"; }

# Function to log bold magenta messages
log_bold_magenta() { echo -e "\033[1;35m$1\033[0m"; }

# Function to display the usage information of the script
usage() {
    echo -e "$(log_blue "$SEPARATOR")\n"
    echo -e "$(log_white 'Usage: {run|build|test|clean|deploy|build_gen|locale_gen|splash_gen|icon_gen|fvm} {dev|staging|prod}')\n"
    echo -e "$(log_blue "$SEPARATOR")\n"
    echo -e "$(log_bold_magenta 'Commands:')"
    echo -e "$(log_white '  run                     - Run the Flutter app on emulator or connected device')"
    echo -e "$(log_white '  build                   - Build the Flutter app (debug or release)')"
    echo -e "$(log_white '  test                    - Run tests for the Flutter app')"
    echo -e "$(log_white '  clean                   - Clean the build directory')"
    echo -e "$(log_white '  deploy                  - Deploy the Flutter app to a device or server')"
    echo -e "$(log_white '  build_gen               - Run the build_runner builder')"
    echo -e "$(log_white '  locale_gen              - Run the easy localization builder')"
    echo -e "$(log_white '  splash_gen              - Run the native splash screen builder')"
    echo -e "$(log_white '  icon_gen                - Run the app icon builder')"
    echo -e "$(log_white '  fvm_info                - Check the Flutter version using FVM')"
    echo -e "$(log_white '  dev | staging | prod    - Sets the environment parameters')"
    echo -e "$(log_yellow "$SEPARATOR")\n"
    echo -e "$(log_white 'To exit the script, type "exit".')"
}
fvm_info() {
    fvm doctor | while IFS= read -r line; do
        echo -e "$(log_green "$line")"
    done
}
check_fvm() {
    if [ ! -f "$CONFIG_FILE" ]; then
        echo "Error: Configuration file '$CONFIG_FILE' is missing."
        echo "Please ensure the file exists and contains the required Flutter version."
        # Check if FVM is installed
        if ! command -v fvm &>/dev/null; then
            echo "$(log_red 'FVM is not installed. Please install it using Homebrew.')"
            echo "$(log_yellow 'Run the following command to install FVM:')"
            echo "$(log_cyan 'brew install fvm')"
            # Prompt user to install FVM
            echo "$(log_yellow 'Would you like to install FVM now? (y/n)')"
            read -r response
            if [[ "$response" =~ ^[Yy]$ ]]; then
                if command -v brew &>/dev/null; then
                    brew install fvm
                    if [ $? -ne 0 ]; then
                        echo "$(log_red 'Failed to install FVM. Please try installing it manually.')"
                        exit 1
                    fi
                    echo "$(log_green 'FVM installed successfully.')"
                else
                    echo "$(log_red 'Homebrew is not installed. Please install Homebrew first by visiting https://brew.sh.')"
                    exit 1
                fi
            else
                echo "$(log_red 'Exiting. Please install FVM and try again.')"
                exit 1
            fi
        fi

        echo "$(log_white 'Available stable Flutter versions:')"
        fvm releases
        echo "$(log_yellow 'Would you like to create a new configuration file? (y/n)')"
        read -r response
        if [[ "$response" =~ ^[Yy]$ ]]; then
            echo "$(log_yellow 'Please select a Flutter version from the list above:')"
            read -r selected_version
            echo "$selected_version" >"$CONFIG_FILE"
            echo "$(log_green "Configuration file '$CONFIG_FILE' created with version '$selected_version'.")"
            fvm use $selected_version
        else
            echo "$(log_red 'Exiting. Please create the configuration file manually.')"
            exit 1
        fi
        if ! command -v fvm &>/dev/null; then
            echo "$(log_red 'FVM is not installed. Please install FVM first by running:')"
            echo "$(log_yellow 'flutter pub global activate fvm')"
            exit 1
        fi
    fi
}
use_fvm() {
    check_fvm
    echo -e "$(log_white "$SEPARATOR")\n"
    echo -e "$(log_green 'Checking Flutter version using FVM...')"
    fvm flutter doctor
    echo -e "$(log_white "$SEPARATOR")\n"
}
build() {
    load_env_configs "$ENVIRONMENT"
    locale_gen
    build_gen
    echo -e "$(log_bold_magenta '\nAvailable platforms:\n')"
    echo -e "[1] ios : Build for iOS\n"
    echo -e "[2] android : Build for Android\n"
    read -p "$(echo -e "Select platform: ")" choice
    case $choice in
    [i]* | [1])
        echo -e "$(log_green 'Building for iOS')"
        build_ios
        ;;
    [a]* | [2])
        echo -e "$(log_green 'Building for Android(aab)')"
        build_android
        ;;
    *)
        echo -e "$(log_red 'Deployment cancelled.')"
        ;;
    esac
    echo -e "$(log_white 'Building with FVM Flutter...')"
    fvm flutter build --dart-define-from-file=".env/$ENVIRONMENT.json"
    echo -e "$(log_white "$SEPARATOR")\n"
}
auto_build() {
    load_env_configs "$ENVIRONMENT"
    locale_gen
    build_gen
    build_ios
    build_android
}
test() {
    echo -e "$(log_white "$SEPARATOR")\n"
    echo -e "$(log_green 'Running Flutter tests...')"
    fvm flutter test $(PROJECT_PATH)
    echo -e "$(log_white "$SEPARATOR")\n"
}
load_env_configs() {
    local stage="$1"
    if [[ -f ".env/$stage.json" ]]; then
        local env_vars=$(jq -r 'to_entries | map("\(.key)=\(.value)") | .[]' ".env/$stage.json")
        for var in $env_vars; do
            export "$var"
        done
    else
        echo -e "$(log_red 'Environment file .env/$stage.json not found!')"
    fi
}
icon_gen() {
    echo -e "$(log_white "$SEPARATOR")\n"
    echo -e "$(log_green 'Running app icon builder...')"
    fvm flutter pub run flutter_launcher_icons:main
    echo -e "$(log_white "$SEPARATOR")\n"
}
splash_gen() {
    echo -e "$(log_white "$SEPARATOR")\n"
    echo -e "$(log_green 'Running native splash screen builder...')"
    fvm dart run flutter_native_splash:create --path=flutter_native_splash.yaml
    echo -e "$(log_white "$SEPARATOR")\n"
}
locale_gen() {
    echo -e "$(log_white "$SEPARATOR")\n"
    echo -e "$(log_green 'Running easy localization builder...')"
    fvm dart run easy_localization:generate -S assets/locale -f keys -O $PROJECT_PATH/lib/src/localization/generated -o locale_keys.g.dart
    echo -e "$(log_white "$SEPARATOR")\n"
}
build_gen() {
    echo -e "$(log_white "$SEPARATOR")\n"
    echo -e "$(log_green 'Running build_runner...')"
    fvm flutter pub run build_runner build --delete-conflicting-outputs
    echo -e "$(log_white "$SEPARATOR")\n"
}
clean() {
    echo -e "$(log_blue "$SEPARATOR")\n"
    rm -rf build .dart_tool
    echo -e "$(log_white 'Cleaning CocoaPods cache...')"
    pod cache clean --all
    rm -rf ios/Pods ios/Podfile.lock || { echo -e "$(log_red 'Failed to clean CocoaPods cache!')"; }
    echo -e "$(log_green 'Cleaning the build directory...')"
    fvm flutter clean
    echo -e "$(log_blue "$SEPARATOR")\n"
}
run() {
    load_env_configs "$ENVIRONMENT"
    echo -e "$(log_white 'Running with FVM Flutter...')"
    fvm flutter run --dart-define-from-file=".env/$ENVIRONMENT.json"
    echo -e "$(log_white "$SEPARATOR")\n"
}
build_android() {
    # Ensure the ENVIRONMENT is valid
    case "$ENVIRONMENT" in
    dev | staging | prod) ;;
    *)
        echo -e "$(log_red 'Invalid stage!')"
        return 1
        ;;
    esac

    # Check for Flutter installation
    if ! command -v flutter &>/dev/null; then
        echo -e "$(log_red 'Flutter is not installed or not in PATH.')"
        return 1
    fi

    # Check for FVM installation
    if ! command -v fvm &>/dev/null; then
        echo -e "$(log_red 'FVM is not installed or not in PATH.')"
        return 1
    fi

    # Check if inside a Flutter project
    if [[ ! -f "pubspec.yaml" ]]; then
        echo -e "$(log_red 'pubspec.yaml not found. Are you in a Flutter project directory?')"
        return 1
    fi

    # Check for environment file
    local env_file=".env/$ENVIRONMENT.json"
    if [[ ! -f "$env_file" ]]; then
        echo -e "$(log_red 'Environment file not found: $env_file')"
        return 1
    fi

    # Check for the Android platform directory
    if [[ ! -d "android" ]]; then
        echo -e "$(log_yellow 'Android directory not found. Creating it with flutter create...')"
        flutter create --platforms android .
    fi

    # Ensure dependencies are resolved
    echo -e "$(log_white 'Running flutter pub get to resolve dependencies...')"
    fvm flutter pub get || {
        echo -e "$(log_red 'Failed to resolve dependencies. Check your pubspec.yaml.')"
        return 1
    }

    # Set environment and build
    load_env_configs "$ENVIRONMENT"
    echo -e "$(log_yellow 'Starting the AAB build...')"
    if ! fvm flutter build aab --release --dart-define-from-file="$env_file"; then
        echo -e "$(log_red 'Build failed. Please check the output above for details.')"
        return 1
    fi

    echo -e "$(log_green 'Android build complete.')"
    echo -e "$(log_green 'AAB file location: ./build/app/outputs/bundle/release')"
}
build_ios() {
    clean
    local env_file=".env/$ENVIRONMENT.json"
    if [[ ! -f "$env_file" ]]; then
        echo -e "$(log_red 'Environment file not found: $env_file')"
        return 1
    fi

    # Log the start of the iOS build process
    echo -e "$(log_green 'Building Flutter project for iOS...')"

    # Ensure Flutter iOS-specific artifacts are up to date
    echo -e "$(log_white 'Precaching iOS-specific Flutter artifacts...')"
    fvm flutter precache --ios || {
        echo -e "$(log_red 'Failed to precache iOS artifacts!')"
        return 1
    }

    # Ensure the Flutter iOS project is created
    if [[ ! -d "ios" ]]; then
        echo -e "$(log_white 'iOS folder not found. Initializing the project...')"
        fvm flutter create --platforms ios . || {
            echo -e "$(log_red 'Failed to initialize iOS platform!')"
            return 1
        }
    fi

    # Run Flutter pub get to generate necessary files like Generated.xcconfig
    echo -e "$(log_white 'Running Flutter pub get...')"
    fvm flutter pub get || {
        echo -e "$(log_red 'Failed to run flutter pub get!')"
        return 1
    }

    # Update Info.plist for required configurations
    echo -e "$(log_white 'Configuring iOS Info.plist for dependencies...')"
    local plist_path="ios/Runner/Info.plist"

    # Check and add UILaunchStoryboardName
    if ! /usr/libexec/PlistBuddy -c "Print :UILaunchStoryboardName" "$plist_path" &>/dev/null; then
        /usr/libexec/PlistBuddy -c "Add :UILaunchStoryboardName string LaunchScreen" "$plist_path"
        echo -e "$(log_green 'Added UILaunchStoryboardName to Info.plist')"
    else
        echo -e "$(log_yellow 'UILaunchStoryboardName already exists. Skipping.')"
    fi

    # Check and add NSLocationWhenInUseUsageDescription
    if ! /usr/libexec/PlistBuddy -c "Print :NSLocationWhenInUseUsageDescription" "$plist_path" &>/dev/null; then
        /usr/libexec/PlistBuddy -c "Add :NSLocationWhenInUseUsageDescription string 'We need your location to provide relevant services.'" "$plist_path"
        echo -e "$(log_green 'Added NSLocationWhenInUseUsageDescription to Info.plist')"
    else
        echo -e "$(log_yellow 'NSLocationWhenInUseUsageDescription already exists. Skipping.')"
    fi

    # Check and add NSLocationAlwaysUsageDescription
    if ! /usr/libexec/PlistBuddy -c "Print :NSLocationAlwaysUsageDescription" "$plist_path" &>/dev/null; then
        /usr/libexec/PlistBuddy -c "Add :NSLocationAlwaysUsageDescription string 'We need your location to provide relevant services.'" "$plist_path"
        echo -e "$(log_green 'Added NSLocationAlwaysUsageDescription to Info.plist')"
    else
        echo -e "$(log_yellow 'NSLocationAlwaysUsageDescription already exists. Skipping.')"
    fi

    # Check and add LSApplicationQueriesSchemes
    if ! /usr/libexec/PlistBuddy -c "Print :LSApplicationQueriesSchemes" "$plist_path" &>/dev/null; then
        /usr/libexec/PlistBuddy -c "Add :LSApplicationQueriesSchemes array" "$plist_path"
        echo -e "$(log_green 'Added LSApplicationQueriesSchemes to Info.plist')"
    else
        echo -e "$(log_yellow 'LSApplicationQueriesSchemes already exists. Skipping.')"
    fi

    # Add individual schemes to LSApplicationQueriesSchemes
    for scheme in "http" "https"; do
        if ! /usr/libexec/PlistBuddy -c "Print :LSApplicationQueriesSchemes" "$plist_path" | grep -q "$scheme"; then
            index=$(/usr/libexec/PlistBuddy -c "Print :LSApplicationQueriesSchemes" "$plist_path" | grep -c '<string>')
            /usr/libexec/PlistBuddy -c "Add :LSApplicationQueriesSchemes:$index string $scheme" "$plist_path"
            echo -e "$(log_green "Added $scheme to LSApplicationQueriesSchemes")"
        else
            echo -e "$(log_yellow "$scheme already exists in LSApplicationQueriesSchemes. Skipping.")"
        fi
    done
    echo -e "$(log_white 'Info.plist configuration completed.')"

    # Install CocoaPods dependencies
    echo -e "$(log_white 'Reinstalling CocoaPods dependencies...')"
    (cd ios && pod install) || {
        echo -e "$(log_red 'Failed to install CocoaPods dependencies!')"
        return 1
    }

    # Build the iOS project
    echo -e "$(log_white 'Building the Flutter app for iOS...')"
    fvm flutter build ipa --release --dart-define-from-file="$(pwd)/$env_file"
}
main() {
    for arg in "$@"; do
        case "$arg" in
        dev | prod | staging)
            ENVIRONMENT="$arg"
            ;;
        full-auto)
            on_auto_mode=true
            ;;
        *)
            # Store non-environment arguments
            processed_args+=("$arg")
            ;;
        esac
    done
    set -- "${processed_args[@]}"
    echo -e "$(log_bold_cyan "\\nSetting the $ENVIRONMENT environment\n")"
    if [[ $on_auto_mode ]]; then
        auto_build
    else
        use_fvm
        while true; do
            update_width
            update_separator
            if [[ $# -lt 1 ]]; then
                usage
                echo -e "$(log_yellow 'Please select an option:')"
                read -r input
                case "$input" in
                run | build | test | clean | build_gen | locale_gen | splash_gen | icon_gen | fvm_info)
                    $input || handle_error "Error running $input"
                    ;;
                deploy)
                    echo -e "Available platforms:"
                    echo -e "[1] ios : Build for iOS"
                    echo -e "[2] android : Build for Android"
                    read -p "$(echo -e "Select platform: ")" choice
                    case $choice in
                    [i]* | [1])
                        echo -e "$(log_green 'Building for iOS')"
                        build_ios
                        ;;
                    [a]* | [2])
                        echo -e "$(log_green 'Building for Android(aab)')"
                        build_android
                        ;;
                    *)
                        echo -e "$(log_red 'Deployment cancelled.')"
                        ;;
                    esac
                    ;;
                dev | staging | prod)
                    echo -e "$(log_bold_cyan "\\nSetting the $ENVIRONMENT environment\n")"
                    ENVIRONMENT=$input
                    load_env_configs "$ENVIRONMENT"
                    ;;
                exit)
                    echo -e "$(log_green "$SEPARATOR")\n"
                    echo -e "$(log_green 'Exiting the script.')"
                    echo -e "$(log_green "$SEPARATOR")\n"
                    break
                    ;;
                *)
                    echo -e "$(log_red "$SEPARATOR")\n"
                    echo -e "$(log_red 'Invalid option. Please try again or type "exit" to exit.')"
                    echo -e "$(log_red "$SEPARATOR")\n"
                    ;;
                esac
            else
                case "$1" in
                run | build | test | clean | build_gen | locale_gen | splash_gen | icon_gen | fvm_info)
                    $1 || handle_error "Error running $1"
                    break
                    ;;
                deploy)
                    deploy
                    break
                    ;;
                *)
                    usage
                    exit 1
                    ;;
                esac
            fi
        done
    fi
}

main "$@"
