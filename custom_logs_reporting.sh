#!/bin/bash

# Default configurations
LOG_FILE="/var/log/messages"
BACKUP_DIR="/var/log/backup"
MAX_BACKUPS=2
ANALYSIS_REPORT="$BACKUP_DIR/log_analysis_report.txt"
LOG_CRITERIA=("error" "warning" "critical")
REPORT_FORMAT="text"

# Function to display usage instructions
usage() {
    echo "Usage: $0 [options]"
    echo "Options:"
    echo "  -l, --log-file         Specify the log file to process (default: /var/log/messages)"
    echo "  -b, --backup-dir       Specify the backup directory (default: /var/log/backup)"
    echo "  -m, --max-backups      Specify the maximum number of backups to retain (default: 2)"
    echo "  -c, --config           Specify a configuration file"
    echo "  -r, --report-format    Specify the report format (text or json, default: text)"
    echo "  -h, --help             Display this help message"
    echo
    echo "Examples:"
    echo "  $0 -l /path/to/logfile -b /path/to/backupdir -m 5"
    echo "  $0 -c /path/to/configfile"
    exit 1
}

# Function to load configurations from a file
load_config() {
    if [ -f "$1" ]; then
        source "$1"
        echo "Loaded configuration from $1"
    else
        echo "Error: Configuration file $1 not found."
        exit 1
    fi
}

# Parse command-line options
while [[ $# -gt 0 ]]; do
    key="$1"
    case $key in
        -l|--log-file)
            LOG_FILE="$2"
            shift; shift
            ;;
        -b|--backup-dir)
            BACKUP_DIR="$2"
            shift; shift
            ;;
        -m|--max-backups)
            MAX_BACKUPS="$2"
            shift; shift
            ;;
        -c|--config)
            load_config "$2"
            shift; shift
            ;;
        -r|--report-format)
            REPORT_FORMAT="$2"
            shift; shift
            ;;
        -h|--help)
            usage
            ;;
        *)
            echo "Unknown option: $1"
            usage
            ;;
    esac
done

# Prompt the user for their name, age, and country
read -p "Please enter your name: " USER_NAME
read -p "Please enter your age: " USER_AGE
read -p "Please enter your country: " USER_COUNTRY

# Validate the age input
if ! [[ "$USER_AGE" =~ ^[0-9]+$ ]] || [ "$USER_AGE" -lt 18 ] || [ "$USER_AGE" -gt 60 ]; then
    echo "Error: Age must be a numeric value between 18 and 60."
    exit 1
fi

echo "Hello, $USER_NAME from $USER_COUNTRY! You are $USER_AGE years old."

# Check if the log file exists
if [ -f "$LOG_FILE" ]; then
   
    # Create backup directory if it doesn't exist
    if [ ! -d "$BACKUP_DIR" ]; then
        mkdir -p "$BACKUP_DIR"
        echo "Created backup directory: $BACKUP_DIR"
    fi

    # Rotate backups
    TIMESTAMP=$(date +'%Y%m%d%H%M%S')
    BACKUP_FILE="$BACKUP_DIR/messages.$TIMESTAMP"
    cp "$LOG_FILE" "$BACKUP_FILE"
    
    if [ $? -eq 0 ]; then
        echo "[$USER_NAME] Successfully copied $LOG_FILE to $BACKUP_FILE."
    else
        echo "[$USER_NAME] Error: Failed to copy $LOG_FILE to $BACKUP_FILE."
        exit 1
    fi

    # Clear the log file
    : > "$LOG_FILE"  

    if [ $? -eq 0 ]; then
        echo "[$USER_NAME] Successfully cleared the contents of $LOG_FILE."
    else
        echo "[$USER_NAME] Error: Failed to clear the contents of $LOG_FILE."
        exit 1
    fi

    # Analyze the copied log file and generate a report
    echo "[$USER_NAME] Generating log analysis report..."
    
    if [ "$REPORT_FORMAT" = "json" ]; then
        # JSON format
        {
            echo "{"
            echo "  \"LogFile\": \"$BACKUP_FILE\","
            for CRITERIA in "${LOG_CRITERIA[@]}"; do
                COUNT=$(grep -i "$CRITERIA" "$BACKUP_FILE" | wc -l)
                echo "  \"$CRITERIA\": $COUNT,"
            done
            echo "  \"Timestamp\": \"$TIMESTAMP\""
            echo "}"
        } > "$ANALYSIS_REPORT"
    else
        # Text format (default)
        {
            echo "Log Analysis Report - $TIMESTAMP"
            echo "================================="
            echo "Log File: $BACKUP_FILE"
            for CRITERIA in "${LOG_CRITERIA[@]}"; do
                COUNT=$(grep -i "$CRITERIA" "$BACKUP_FILE" | wc -l)
                echo "$CRITERIA Count: $COUNT"
            done
            echo "================================="
        } > "$ANALYSIS_REPORT"
    fi

    echo "[$USER_NAME] Log analysis report saved to $ANALYSIS_REPORT."

    # Rotate backups and retain only the last $MAX_BACKUPS
    BACKUP_COUNT=$(ls -1q $BACKUP_DIR/messages.* | wc -l)
    if [ "$BACKUP_COUNT" -gt "$MAX_BACKUPS" ]; then
        # Delete older backups
        REMOVE_COUNT=$((BACKUP_COUNT - MAX_BACKUPS))
        echo "[$USER_NAME] Removing $REMOVE_COUNT old backup(s)..."
        ls -1t $BACKUP_DIR/messages.* | tail -n "$REMOVE_COUNT" | xargs rm -f
    fi
else
    echo "[$USER_NAME] Error: $LOG_FILE does not exist."
    exit 1
fi
