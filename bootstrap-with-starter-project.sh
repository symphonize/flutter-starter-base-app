#!/bin/bash

DESTINATION_PATH="$1"
TERMINAL_WIDTH=$(tput cols)
SEPARATOR=$(printf '%*s' "$TERMINAL_WIDTH" '' | tr ' ' '═')
REMOTE_REPO_URL="https://github.com/symphonize/flutter_starter_base_app.git"
log_green() { echo -e "\033[32m$1\033[0m"; }
log_blue() { echo -e "\033[34m$1\033[0m"; }
log_red() { echo -e "\033[31m$1\033[0m"; }
# Check if a destination path was provided
if [ "$#" -ne 1 ]; then
    echo -e "$(log_red "Usage: $0 <destination-path>")\n"
    exit 1
fi

# Expand the destination path to an absolute path, handling tilde and relative paths
if [[ "$DESTINATION_PATH" == "~"* ]]; then
    # Handle tilde expansion manually
    DESTINATION_PATH="$HOME${DESTINATION_PATH:1}"
fi

# Resolve potential relative path (including `.`) to an absolute path
DESTINATION_PATH="$(cd "$DESTINATION_PATH" && pwd)"

# Use system temp directory or fallback to /tmp
temp_repo="${TMPDIR:-/tmp}/temp_repo"

# Prompt for confirmation before proceeding
echo -e "$(log_blue "This will bootstrap '$DESTINATION_PATH' with the Flutter starter project from '$REMOTE_REPO_URL.\n")"
read -p "Are you sure you want to proceed? (y/n): " confirmation
if [[ "$confirmation" != "y" && "$confirmation" != "Y" ]]; then
    echo -e "$(log_red "Operation canceled.")"
    exit 0
fi
echo -e "$(log_blue "$SEPARATOR")\n"

# Clone, archive, and extract
git clone --bare "$REMOTE_REPO_URL" "$temp_repo" &&
    cd "$temp_repo" &&
    git archive master | tar -x -C "$DESTINATION_PATH" &&
    cd .. &&
    rm -rf "$temp_repo"

# Derive new package name from the destination directory name
new_package_name=$(basename "$DESTINATION_PATH")

# Derive old package name from the remote repository URL
old_package_name=$(basename "$REMOTE_REPO_URL" .git)

# Echo the old and new package names
echo "Old package name: $old_package_name"
echo "New package name: $new_package_name"

# Update Flutter package names in pubspec.yaml
echo "Updating Flutter package names in pubspec.yaml files..."
find "$DESTINATION_PATH" -type f -name "pubspec.yaml" -exec sh -c 'sed -i "" "s/^name:.*/name: $1/" "$2" && echo "Updated $2"' _ "$new_package_name" {} \;

# Update Flutter package imports in Dart files within the /lib directory
echo "Updating Flutter package imports in Dart source files..."
lib_path="${DESTINATION_PATH}/lib"
if [ -d "$lib_path" ]; then
    find "$lib_path" -type f -name "*.dart" -exec sh -c 'sed -i "" "s/package:$2\//package:$1\//g" "$3" && echo "Updated $3"' _ "$new_package_name" "$old_package_name" {} \;
fi

# Update Flutter package imports in Dart files within the /test directory
echo "Updating Flutter package imports in Dart test files..."
test_path="${DESTINATION_PATH}/test"
if [ -d "$test_path" ]; then
    find "$test_path" -type f -name "*.dart" -exec sh -c 'sed -i "" "s/package:$2\//package:$1\//g" "$3" && echo "Updated $3"' _ "$new_package_name" "$old_package_name" {} \;
fi
echo -e "$(log_green "$SEPARATOR")\n"
# Inform user of success
echo "The destination [${DESTINATION_PATH}] has been successfully bootstrapped with the starter project."
cd $DESTINATION_PATH
ENV_DIR=".env"
ENV_FILE="$ENV_DIR/dev.json"
mkdir -p "$ENV_DIR"
# Create or overwrite the dev.json file with sample content
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
chmod +x setup.sh
sh ./setup.sh "full-auto"
