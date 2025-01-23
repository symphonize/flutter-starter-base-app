#!/bin/bash

# Version:

# Path to the project directory
PROJECT_PATH="$(pwd)"

# Default build mode for the Flutter project
ENVIRONMENT="dev"

# Configuration file in the repository
CONFIG_FILE=".fvmrc"

env_file=".env/$ENVIRONMENT.json"

# Get the terminal width
TERMINAL_WIDTH=$(tput cols)

# Separator line based on the terminal width
SEPARATOR=$(printf '%*s' "$TERMINAL_WIDTH" '' | tr ' ' '═')

# Process the input arguments to extract dev/prod/staging and handle the rest: Array to store the remaining arguments
processed_args=()

on_auto_mode=

# Function to update the separator line whenever the terminal width changes
update_separator() {
  SEPARATOR=$(printf '%*s' "$(tput cols)" '' | tr ' ' '═');
}

# Colors for output
log_prompt() {
  local log_type="$1"
  local message="$2"

  # Define color codes for prompt text
  case "$log_type" in
    bold) color="\033[1;37m" ;;  # Bold White
    success) color="\033[1;32m" ;;  # Bold Green
    warning) color="\033[1;33m" ;;  # Bold Yellow
    error) color="\033[1;31m" ;;  # Bold Red
    cyan) color="\033[1;36m" ;;  # Bold Cyan
    blue) color="\033[1;34m" ;;  # Bold Blue
    magenta) color="\033[1;35m" ;;  # Bold Magenta
    *) color="\033[0m" ;;  # Default (no color)
  esac

  # Return the formatted prompt text
  echo -e "${color}${message}\033[0m"
}

log_message() {
  local log_type="$1"
  local message="$2"

  # Use log_prompt for consistent formatting
  echo "$(log_prompt "$log_type" "$message")"
}

# Wrapper functions for log_message
log_header() {
  log_message "bold" "$1"
}

log_success() {
  log_message "success" "$1"
}

log_warning() {
  log_message "warning" "$1"
}

log_error() {
  log_message "error" "$1"
}


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
help() {
    echo -e "$(log_bold_blue "$SEPARATOR")\n"
    echo -e "$(log_bold_magenta 'Commands:')\n"
    echo -e "$(log_white " [1] create                  - Creates necessary build files and platform files")"
    echo -e "$(log_white " [2] run                     - Run the Flutter app on target device [$FLUTTER_TARGET_DEVICE]")"
    echo -e "$(log_white ' [3] build                   - Build the generated files, icons, splash, locale keys')"
    echo -e "$(log_white ' [4] test                    - Run tests for the Flutter app')"
    echo -e "$(log_white ' [5] clean                   - Clean the build directory')"
    echo -e "$(log_white ' [6] deploy                  - Deploy the Flutter app to a device or server')"
    echo -e "$(log_white ' [7] fvm_info                - Check the Flutter version using FVM')"
    echo -e "$(log_white ' [8] help                    - Exits the application')"
    echo -e "$(log_white ' [9] exit                    - Exits the application')"
    echo -e "$(log_white ' dev | staging | prod        - Sets the environment parameters')"
    echo -e "\n$(log_bold_yellow 'Usage: { run | build | test | clean | deploy | fvm_info | dev | staging | prod }')\n"
    echo -e "\n$(log_bold_magenta 'NOTE: If non-flutter libraries/packages are not recognized, you might need to reload the IDE')\n"
    echo -e "\n$(log_white 'To exit the application, type "exit".')\n"
}

# Helper function to format and display a single menu item
format_menu_item() {
  local number="$1"
  local item="$2"
  local delimiter="|"

  # Extract the option and description using the custom delimiter
  IFS="$delimiter" read -r option description <<< "$item"

  # Print the formatted menu item with dynamic numbering
  printf "$(log_white ' %-3s %-25s %s\n')" "$number)" "$option" "$description"
}


interactive_menu() {

  # Define menu items globally
  local menu_items=(
    "Create|Gives the options of thing this script supports creation of"
    "Run|Run the Flutter app on target device [emulator-5554]"
    "Build Application|Calls all the Required builders fully compile the application "
    "test|Run tests for the Flutter app"
    "Clean|Clean the build directory"
    "Package App Release|This will build and Sign a releasable App for the App Store"
    "FVM Info|This will display the associated environment configuration to determine if it is configured correctly"
  )

  while true; do

  echo -e "$(log_bold_blue "\n$SEPARATOR")\n"
  echo -e "$(log_bold_white "Flutter App Manager ($ENVIRONMENT)\n")"
  echo -e "$(log_bold_blue "$SEPARATOR")\n"

  # Header
  log_bold_cyan "Commands:"

  # Loop through menu items and format each one dynamically
  printf "\n"
  local count=1
  for item in "${menu_items[@]}"; do
    format_menu_item "$count" "$item"
    count=$((count + 1))
  done

  format_menu_item "Q" "Quit|Exit the application"

  read -r -p "$(log_yellow "\nPlease select an option: ")" input

  case "$input" in
  1) create_menu || log_error "Error running $input"
      ;;
  2) run ||  log_error "Error running $input"
      ;;
  3)
      build || echo -e "$(log_bold_red "Error running $input")"
      ;;
  4)
      test || echo -e "$(log_bold_red "Error running $input")"
      ;;
  5)
      clean || echo -e "$(log_bold_red "Error running $input")"
      ;;
  6)
      deploy || echo -e "$(log_bold_red "Error running $input")"
      ;;
  7) fvm_info || log_error "Error running $input"
      ;;
  q | Q | exit)
      exit || echo -e "$(log_bold_red "Error running $input")"
      ;;
  *)
      echo -e "\n$(log_red "$SEPARATOR")\n"
      echo -e "$(log_red 'Invalid option. Please try again or type "exit" to exit.')"
      ;;
  esac
  done
}
create_env_if_missing() {
    ENV_DIR=$(dirname "$ENV_FILE")
    ENV_FILE=".env/$ENVIRONMENT.json"
    if [[ ! -d "$ENV_DIR" ]]; then
        echo -e "$(log_yellow "Directory $ENV_DIR does not exist. Creating it.")"
        mkdir -p "$ENV_DIR"
    fi
    if [[ ! -f "$ENV_FILE" ]]; then
        echo -e "$(log_yellow "File $ENV_FILE does not exist. Creating it with dummy data.")"
        cat >"$ENV_FILE" <<EOF
{
  "API_URL": "https://api.example.com",
  "API_VERSION": {
    "HOST": "localhost",
    "PORT": 5432,
    "USER": "username",
    "PASSWORD": "password"
  },
  "LOG_LEVEL": "debug"
}
EOF
    fi
}
create_platform_specific_files() {
    if ! fvm flutter create --platforms ios,android .; then
        echo "$(log_red 'Unable to create platform specific files')"
        return 1
    fi
}
create_menu() {

  # Define menu items globally
  local menu_items=(
    "Create App|Creates a Brand new Flutter App using our standards"
    "Create Icon|Creates a new Icon for the Mobile App"
    "Create Splash|Creates the Splash Screen for the Mobile App"
  )

  while true; do

  echo -e "$(log_bold_blue "\n$SEPARATOR")\n"
  echo -e "$(log_bold_white "Flutter App Manager ($ENVIRONMENT) => Create Menu\n")"
  echo -e "$(log_bold_blue "$SEPARATOR")\n"

  # Header
  log_bold_cyan "Commands:"

  # Loop through menu items and format each one dynamically
  printf "\n"
  local count=1
  for item in "${menu_items[@]}"; do
    format_menu_item "$count" "$item"
    count=$((count + 1))
  done
  format_menu_item "C" "Cancel|Go back to previous menu"

  read -r -p "$(log_yellow "\nPlease select an option: ")" input
    case "$input" in
      1) create_app || log_error "Error running $input"
          ;;
      2) icon_gen ||  log_error "Error running $input"
          ;;
      3) splash_gen || echo -e "$(log_bold_red "Error running $input")"
          ;;
      c|C) return
          ;;
      *)
          echo -e "\n$(log_red "$SEPARATOR")\n"
          echo -e "$(log_red 'Invalid option. Please try again or type "exit" to exit.')"
          ;;
    esac

  done

}

create_app() {
    echo -e "\n$(log_bold_magenta "$SEPARATOR")\n"
    create_env_if_missing
    create_fvm_if_missing
    fvm flutter pub get
    create_platform_specific_files
    build
}

fvm_info() {
    fvm doctor | while IFS= read -r line; do
        echo -e "$(log_green "$line")"
    done
}
# Create FVM if missing
create_fvm_if_missing() {
  if [ ! -f "$CONFIG_FILE" ]; then
    log_error "Configuration file '$CONFIG_FILE' is missing."
    log_warning "Please ensure the file exists and contains the required Flutter version."
    if ! command_exists fvm; then
      log_error "FVM is not installed. Please install it using Homebrew."
      log_warning "Run the following command to install FVM:"
      log_cyan "brew install fvm"
      read -r -p "$(log_prompt 'yellow' 'Would you like to install FVM now? (y/n): ')" response
      if [[ "$response" =~ ^[Yy]$ ]]; then
        if command_exists brew; then
          brew install fvm
          if [ $? -ne 0 ]; then
            log_error "Failed to install FVM. Please try installing it manually."
            return 1
          fi
          log_success "FVM installed successfully."
        else
          log_error "Homebrew is not installed. Please install Homebrew first by visiting https://brew.sh."
          return 1
        fi
      else
        log_error "Exiting. Please install FVM and try again."
        return 1
      fi
    fi
  fi
  echo "$(log_white 'Available stable Flutter versions:')"
  fvm releases
  echo "$(log_yellow 'Would you like to create a new configuration file? (y/n)')"
  read -r response
  if [[ "$response" =~ ^[Yy]$ ]]; then
      echo "$(log_yellow 'Please select a Flutter version from the list above:')"
      read -r selected_version
      echo "$(log_green "Configuration file '$CONFIG_FILE' created with version '$selected_version'.")"
      fvm use $selected_version
  else
      echo "$(log_red 'Exiting. Please create the configuration file manually.')"
      return 1
  fi
  if ! command -v fvm &>/dev/null; then
      echo "$(log_red 'FVM is not installed. Please install FVM first by running:')"
      echo "$(log_yellow 'flutter pub global activate fvm')"
      return 1
  fi
}

deploy_prep() { build; }
deploy() {
    echo -e "\n$(log_green "$SEPARATOR")\n"
    echo "$(log_yellow 'Would you like to build generated files? (y/n)')"
    read -r response
    if [[ "$response" =~ ^[Yy]$ ]]; then
        build
    fi
    case "$ENVIRONMENT" in
    dev | staging | prod) ;;
    *)
        echo -e "$(log_red 'Invalid envrionment!')"
        return 1
        ;;
    esac
    env_file=".env/$ENVIRONMENT.json"
    if [[ ! -f "$env_file" ]]; then
        echo
        echo -e "$(log_red "Environment file not found: $env_file")"
        return 1
    fi
    echo
    echo -e "$(log_white 'Running flutter pub get to resolve dependencies...')"
    fvm flutter pub get || {
        echo -e "$(log_red 'Failed to resolve dependencies. Check your pubspec.yaml.')"
        return 1
    }
    echo
    echo "$(log_yellow 'Would you like to deploy for ios? (y/n)')"
    read -r response
    if [[ "$response" =~ ^[Yy]$ ]]; then
        build_ios
    fi
    echo
    echo "$(log_yellow 'Would you like to deploy for android? (y/n)')"
    read -r response
    if [[ "$response" =~ ^[Yy]$ ]]; then
        build_android
    fi
}
build() {
    echo "$(log_yellow "Building for $ENVIRONMENT")"
    icon_gen
    build_gen
    locale_gen
    splash_gen
    echo "$(log_bold_green "Build finished")"
}
# Target device needs to be reachable by flutter
devices() {
    # Get the list of connected devices
    DEVICE_LIST=$(fvm flutter devices --machine)

    # Check if any device is available
    if [[ -z "$DEVICE_LIST" || "$DEVICE_LIST" == "[]" ]]; then
        echo "No devices found. Please connect a device or start an emulator."
        return 1
    fi
    # Parse the device information
    echo "Connected Flutter devices:"
    echo "$DEVICE_LIST" | jq -r '.[] | "\(.name) (\(.id)) - \(.platform)"'

    # Select the first available device (optional)
    FIRST_DEVICE=$(echo "$DEVICE_LIST" | jq -r '.[0].id')
    echo "First device detected: $FIRST_DEVICE"

    # Set an environment variable for the selected device (optional)
    export FLUTTER_TARGET_DEVICE="$FIRST_DEVICE"
    echo "FLUTTER_TARGET_DEVICE set to $FIRST_DEVICE"
    DEVICE_INFO=$(flutter devices | grep "$FIRST_DEVICE")
    # if [[ "$DEVICE_INFO" == *"ios"* ]]; then
    #     build_ios
    # elif [[ "$DEVICE_INFO" == *"android"* ]]; then
    #     build_android
    # fi
}
test() {
    create_fvm_if_missing
    echo -e "$(log_cyan "$SEPARATOR")\n"
    echo -e "$(log_bold_magenta 'Running Flutter tests...')"
    fvm flutter test
}
icon_gen() {
    echo -e "$(log_blue "$SEPARATOR")\n"
    # Check for the Android platform directory
    if [[ ! -d "android" ]]; then
        echo -e "$(log_yellow 'Android directory not found. Creating it with flutter create...')"
        fvm flutter create --platforms android .
    fi
    # Ensure the Flutter iOS project is created
    if [[ ! -d "ios" ]]; then
        echo -e "$(log_white 'iOS folder not found. Initializing the project...')"
        fvm flutter create --platforms ios . || {
            echo -e "$(log_red 'Failed to initialize iOS platform!')"
            return 1
        }
    fi
    echo -e "$(log_bold_magenta 'Running app icon builder...')"
    if ! fvm flutter pub run flutter_launcher_icons:main; then
        echo -e "$(log_red 'Failed to generate launch icons. Please check your configuration.')"
        return 1
    fi
    echo -e "$(log_green 'Successfully built icons')"
}
splash_gen() {
    echo -e "\n$(log_blue "$SEPARATOR")\n"
    echo -e "$(log_bold_magenta 'Running native splash screen builder...')"
    if ! fvm dart run flutter_native_splash:create --path=flutter_native_splash.yaml; then
        echo -e "$(log_red 'Failed to generate splash screen. Please check your configuration.')"
        return 1
    fi
    echo -e "$(log_green 'Successfully built splash')"
}
locale_gen() {
    echo -e "\n$(log_blue "$SEPARATOR")\n"
    echo -e "$(log_bold_magenta 'Running easy localization builder...')"
    if ! fvm dart run easy_localization:generate -S assets/locale -f keys -O $PROJECT_PATH/lib/src/localization/generated -o locale_keys.g.dart; then
        echo -e "$(log_red 'Failed to generate localization keys. Please check your configuration.')"
        return 1
    fi
    echo -e "$(log_green 'Successfully built localization keys')"

}
build_gen() {
    echo -e "\n$(log_blue "$SEPARATOR")\n"
    echo -e "$(log_bold_magenta 'Running build_runner...')"
    if ! fvm flutter pub run build_runner build --delete-conflicting-outputs; then
        echo -e "$(log_red 'Failed to build generated files. Please check your configuration.')"
        return 1
    fi
    echo
    echo -e "$(log_green 'Successfully built generated files')"
}
clean() {
    echo -e "\n$(log_yellow "$SEPARATOR")\n"
    rm -rf build .dart_tool
    echo -e "$(log_bold_yellow 'Cleaning CocoaPods cache...')"
    pod cache clean --all
    rm -rf ios/Pods ios/Podfile.lock || { echo -e "$(log_red 'Failed to clean CocoaPods cache!')"; }
    echo -e "$(log_bold_yellow 'Cleaning the build directory...')"
    fvm flutter clean || {
        echo -e "$(log_red 'Failed to clean')"
        return 1
    }
    echo -e "\033[H\033[J"
    echo -e "$(log_bold_green 'Successfully cleaned\n')"
}
run() {
    build
    echo -e "$(log_white 'Running with FVM Flutter...')"
    fvm flutter run --dart-define-from-file=".env/$ENVIRONMENT.json"
    echo -e "$(log_white "$SEPARATOR")\n"
}
build_android() {
    # Check for the Android platform directory
    if [[ ! -d "android" ]]; then
        echo -e "$(log_yellow 'Android directory not found. Creating it with flutter create...')"
        fvm flutter create --platforms android .
    fi

    # Set environment and build
    echo -e "$(log_yellow 'Starting the AAB build...')"
    if ! fvm flutter build aab --release --dart-define-from-file="$env_file"; then
        echo -e "$(log_red 'Build failed. Please check the output above for details.')"
        return 1
    fi
}
build_ios() {
    echo -e "$(log_green 'Building Flutter project for iOS...')"
    # Ensure the Flutter iOS project is created
    if [[ ! -d "ios" ]]; then
        echo -e "$(log_white 'iOS folder not found. Initializing the project...')"
        fvm flutter create --platforms ios . || {
            echo -e "$(log_red 'Failed to initialize iOS platform!')"
            return 1
        }
    fi
    # Ensure Flutter iOS-specific artifacts are up to date
    echo -e "$(log_white 'Precaching iOS-specific Flutter artifacts...')"
    fvm flutter precache --ios || {
        echo -e "$(log_red 'Failed to precache iOS artifacts!')"
        return 1
    }

    # Install CocoaPods dependencies
    echo -e "$(log_white 'Reinstalling CocoaPods dependencies...')"
    (cd ios && pod install && cd ..) || {
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
            processed_args+=("$arg")
            ;;
        esac
    done
    set -- "${processed_args[@]}"
#    echo -e "$(log_bold_cyan "\\nSetting the $ENVIRONMENT environment\n")"

      update_separator
      if [[ $# -lt 1 ]]; then
          interactive_menu
      else
          case "$1" in
          --help|help) show_help ;;
          clean)
              clean || log_error "Error running $1"
              return 0
              ;;
          create-app)
              create-app || log_error "Error running $1"
              return 0
              ;;
          create-splash)
              splash-gen || log_error "Error running $1"
              return 0
              ;;
          create-icon)
              icon_gen || log_error "Error running $1"
              return 0
              ;;
          run | build | test  | deploy | fvm_info)
              $1 || echo -e "$(log_bold_red "Error running $1")"
              return 0
              ;;
          *)
              show_help
              return 1
              ;;
          esac
      fi

}
main "$@"
