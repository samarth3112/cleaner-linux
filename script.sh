#!/bin/bash

METRICS_DIR="/var/metrics"
THRESHOLD=20  # Usage threshold in percentage
BLOB_MOUNT="/root/blobfuse"  # Mount path of Blob Fuse
LOG_FILE="/var/log/metrics.log"  # Log file path

# Function to calculate disk usage of a directory
get_directory_usage() {
    local dir_path=$1
    local usage_percentage=$(df -P "$dir_path" | awk 'NR==2 {print int($3/$2*100)}')
    echo "$usage_percentage"
}

# Function to copy files to Blob storage using Blob Fuse
copy_files_to_blob() {
    local src_dir=$1
    local dest_dir=$2
    cp -r "$src_dir" "$dest_dir"
}

# Function to delete files in a directory
delete_files() {
    local dir=$1
    local files=("$dir"/*)
    local files_before_deletion=("${files[@]##*/}")

    rm -f "$dir"/*

    echo "Deleted files:" >> "$LOG_FILE"
    printf '%s\n' "${files_before_deletion[@]}" >> "$LOG_FILE"
}

# Main logic
usage=$(get_directory_usage "$METRICS_DIR")
echo "Current disk usage: $usage%"

echo "Disk usage: $usage%" >> "$LOG_FILE"

if [ "$usage" -ge "$THRESHOLD" ]; then
    echo "Disk usage threshold exceeded. Taking necessary actions..."
    echo "Copying files to Blob storage..." >> "$LOG_FILE"
    copy_files_to_blob "$METRICS_DIR" "$BLOB_MOUNT"

    echo "Deleting files to reduce disk usage..." >> "$LOG_FILE"
    delete_files "$METRICS_DIR"

    echo "Files copied and deleted successfully." >> "$LOG_FILE"
else
    echo "Disk usage is within the threshold. No action required."
fi
