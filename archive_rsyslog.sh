#!/bin/bash

# This script will find files older than 2 days old in the /data/syslog directory and compress them with bzip2
# Files older than 365 days are deleted
# Empty directories are deleted
# If a file that is found with the find command has an existing counterpart .bz2 file, it temporarily renames the primary file, uncompresses the file it found, then appends to new file to the old, then recompresses.

date=$(date +"%Y%m%d")
lockf="/data/syslog/.archive_syslog.lock"
logfile="/data/syslog/archive_syslog.$date.log"

if [ -f "$lockf" ]; then
    pid=$(cat "$lockf")
    if [ -d "/proc/$pid" ]; then
        echo "Another instance of this script is still running, skipping this run..." >> "$logfile"
        exit 1
    fi
    rm "$lockf"
fi

echo $$ > "$lockf"

start_time=$(date +"%Y-%m-%d %H:%M:%S")

echo "[$$] START $start_time" >> "$logfile"

basedir="/data/syslog"
today=$(date +"%Y/%m/%d")

# Compress and merge files
find "$basedir" -mtime +2 -type f ! -name "*bz2" | while IFS= read -r file; do
    if [[ -f "$basedir/$file.bz2" ]]; then
        echo "Merging $file into pre-compressed file..." >> "$logfile"
        mv "$file" "$file.cat"
        bunzip2 "$file.bz2"
        cat "$file.cat" >> "$file"
        rm "$file.cat"
        echo "Recompressing $file" >> "$logfile"
        bzip2 -9 "$file"
    else
        echo "Compressing $file" >> "$logfile"
        bzip2 -9 "$file"
    fi
done

# Clean up old files and empty directories
echo "Cleaning up old files and empty directories..." >> "$logfile"
find "$basedir" -type f -mtime +365 -exec rm {} \;
find "$basedir" -type d -empty -print -delete >> "$logfile"

end_time=$(date +"%Y-%m-%d %H:%M:%S")

echo "[$$] DONE $end_time" >> "$logfile"

rm "$lockf"
