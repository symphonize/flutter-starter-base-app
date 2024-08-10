#!/bin/bash

# Check if a destination path was provided
if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <destination-path>"
    exit 1
fi

# Set the remote repository URL directly in the script
remote_repo_url="https://github.com/symphonize/flutter_starter_base_app.git"

# Assign command line argument to variable for the destination path
destination_path="$1"

# Expand the destination path to an absolute path, handling tilde and relative paths
if [[ "$destination_path" == "~"* ]]; then
  # Handle tilde expansion manually
  destination_path="$HOME${destination_path:1}"
fi

# Resolve potential relative path (including `.`) to an absolute path
destination_path="$(cd "$destination_path" && pwd)"

# Use system temp directory or fallback to /tmp
temp_repo="${TMPDIR:-/tmp}/temp_repo"

# Prompt for confirmation before proceeding
echo "This will bootstrap '$destination_path' with the Flutter starter project from '$remote_repo_url'."
read -p "Are you sure you want to proceed? (y/n): " confirmation
if [[ "$confirmation" != "y" && "$confirmation" != "Y" ]]; then
    echo "Operation canceled."
    exit 0
fi

# Clone, archive, and extract
git clone --bare "$remote_repo_url" "$temp_repo" && \
cd "$temp_repo" && \
git archive master | tar -x -C "$destination_path" && \
cd .. && \
rm -rf "$temp_repo"

# Derive new package name from the destination directory name
new_package_name=$(basename "$destination_path")

# Derive old package name from the remote repository URL
old_package_name=$(basename "$remote_repo_url" .git)

# Echo the old and new package names
echo "Old package name: $old_package_name"
echo "New package name: $new_package_name"

# Update Flutter package names in pubspec.yaml
echo "Updating Flutter package names in pubspec.yaml files..."
find "$destination_path" -type f -name "pubspec.yaml" -exec sh -c 'sed -i "" "s/^name:.*/name: $1/" "$2" && echo "Updated $2"' _ "$new_package_name" {} \;

# Update Flutter package imports in Dart files within the /lib directory
echo "Updating Flutter package imports in Dart source files..."
lib_path="${destination_path}/lib"
if [ -d "$lib_path" ]; then
    find "$lib_path" -type f -name "*.dart" -exec sh -c 'sed -i "" "s/package:$2\//package:$1\//g" "$3" && echo "Updated $3"' _ "$new_package_name" "$old_package_name" {} \;
fi

# Update Flutter package imports in Dart files within the /test directory
echo "Updating Flutter package imports in Dart test files..."
test_path="${destination_path}/test"
if [ -d "$test_path" ]; then
    find "$test_path" -type f -name "*.dart" -exec sh -c 'sed -i "" "s/package:$2\//package:$1\//g" "$3" && echo "Updated $3"' _ "$new_package_name" "$old_package_name" {} \;
fi

# Inform user of success
echo "The destination [${destination_path}] has been successfully bootstrapped with the starter project."

# change directory to the ${destination_path}
echo "Navigating to Destination Directory [${destination_path}]"
cd ${destination_path}

# Run pub get
echo "Running flutter pub get..."
flutter pub get

# Store the current directory
current_dir=$(pwd)
echo "Initial directory: ${current_dir}"

# Check if the ios directory exists before trying to cd into it
ios_dir="$destination_path/ios"
if [ -d "$ios_dir" ]; then
    echo "Navigating to iOS directory [${ios_dir}]..."
    cd "$ios_dir"
    pod install
    echo "Returning to the previous directory [${current_dir}]..."
    cd "$current_dir"
else
    echo "iOS directory [${ios_dir}] not found, skipping pod install."
fi

# Check if flutter_native_splash.yaml exists in the destination directory
splash_config_file="$destination_path/flutter_native_splash.yaml"
splash_image_file="$destination_path/assets/splash.jpg"


if [ -f "$splash_config_file" ] && [ -f "$splash_image_file" ]; then
    # Prompt the user if they want to create the splash screen
    echo "flutter_native_splash.yaml and assets/splash.jpg found."
    read -p "Would you like to create the splash screen now? (y/n): " create_splash
    if [[ "$create_splash" == "y" || "$create_splash" == "Y" ]]; then
        echo "Creating splash screen..."
        dart run flutter_native_splash:create --path="$splash_config_file"
    else
        echo "Skipping splash screen creation."
    fi
else
    echo "flutter_native_splash.yaml or assets/splash.jpg not found, skipping splash screen creation."
fi

# Run localization generation
echo "Generating localization files..."
flutter pub run easy_localization:generate -S assets/locale -f keys -O lib/src/localization/generated -o locale_keys.g.dart

# Generate the .g.dart file
echo "Generating .g.dart files..."
flutter pub run build_runner build base_detail_field --delete-conflicting-outputs
