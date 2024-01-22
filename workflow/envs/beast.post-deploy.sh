#!env bash
set -o pipefail
set -e # Exit on error

# Define the version variable
VERSION="2.7.6"
# array of packages to install
PACKAGES=("ReMASTER")

# Function to download, install, and symlink
download_install_symlink() {
    os=$(uname -s)
    arch=$(uname -m)
    file=""

    # change to the envs directory
    cd $CONDA_PREFIX

    # Download and Install
    if [[ "$os" == "Darwin" ]]; then
        file="BEAST.v$VERSION.Mac.dmg"
        curl -LO "https://github.com/CompEvol/beast2/releases/download/v$VERSION/$file"
        hdiutil mount "$file"  # This mounts the dmg file
        cp -R "/Volumes/BEAST v$VERSION/BEAST $VERSION/" "$CONDA_PREFIX/lib/beast"
        hdiutil unmount "/Volumes/BEAST v$VERSION/"
    elif [[ "$os" == "Linux" ]]; then
        if [[ "$arch" == "x86_64" ]]; then
            file="BEAST.v$VERSION.Linux.x86.tgz"
        elif [[ "$arch" == "aarch64" ]]; then
            file="BEAST.v$VERSION.Linux.aarch64.tgz"
        else
            echo "Unsupported architecture"
            return 1
        fi
        curl -LO "https://github.com/CompEvol/beast2/releases/download/v$VERSION/$file"
        tar -xzvf "$file"
        mv beast "$CONDA_PREFIX/lib/beast"
    else
        echo "Unsupported operating system"
        return 1
    fi

    # Create symlinks
    for cmd in "$CONDA_PREFIX/lib/beast/bin/"*; do
        ln -sf "$cmd" "$CONDA_PREFIX/bin/"
    done
    
    # Remove the downloaded file
    rm -rf "$file"
}

# Call the function
download_install_symlink

# This script is used to add packages to beast after the beast.yaml env is installed
beast -version  # Need to call beast once (even just to query the version) to create support dirs

# Install packages
for package in "${PACKAGES[@]}"; do
    packagemanager -add "$package"
done

# Ensure beagle is available
# Activate script: Set up LD_LIBRARY_PATH for beagle
echo -e 'export LD_LIBRARY_PATH_CONDA_BACKUP="${LD_LIBRARY_PATH:-}"\nexport LD_LIBRARY_PATH=$CONDA_PREFIX/lib' > $CONDA_PREFIX/etc/conda/activate.d/beagle_activate.sh

# Deactivate script: Restore original LD_LIBRARY_PATH and clean up
echo -e 'export LD_LIBRARY_PATH=${LD_LIBRARY_PATH_CONDA_BACKUP:-}\nunset LD_LIBRARY_PATH_CONDA_BACKUP\n[ -z $LD_LIBRARY_PATH ] && unset LD_LIBRARY_PATH' > $CONDA_PREFIX/etc/conda/deactivate.d/beagle_deactivate.sh