#!/bin/bash

# Default configurations
LOG_FILE="/mnt/d/devops/log/messages"
BACKUP_DIR="/mnt/d/devops/log/backup"
MAX_BACKUPS=2
ANALYSIS_REPORT="$BACKUP_DIR/log_analysis_report.txt"
LOG_CRITERIA=("error" "warning" "critical")
REPORT_FORMAT="text"
DEBUG_MODE=false


usage() {
    echo "Usage: $0 [options]"
    echo "Options:"
    echo "  -l, --log-file         Specify the log file to process (default: /var/log/messages)"
    echo "  -b, --backup-dir       Specify the backup directory (default: /var/log/backup)"
    echo "  -m, --max-backups      Specify the maximum number of backups to retain (default: 2)"
    echo "  -c, --config           Specify a configuration file"
    echo "  -r, --report-format    Specify the report format (text or json, default: text)"
    echo "  -d, --debug            Enable debug mode"
    echo "  -h, --help             Display this help message"
    echo
    echo "Examples:"
    echo "  $0 -l /path/to/logfile -b /path/to/backupdir -m 5"
    echo "  $0 -c /path/to/configfile"
    exit 1
}


load_config() {
    if [ -f "$1" ]; then
        source "$1"
        debug "Loaded configuration from $1"
    else
        echo "Error: Configuration file $1 not found."
        exit 1
    fi
}

# Debug function to log messages if debug mode is enabled
debug() {
    if [ "$DEBUG_MODE" = true ]; then
        echo "[DEBUG] $(date +'%Y-%m-%d %H:%M:%S') - $1"
    fi
}

# Function to monitor CPU usage
monitor_cpu() {
    debug "Monitoring CPU usage..."
    CPU_USAGE=$(top -b -n1 | grep "Cpu(s)" | awk '{print $2 + $4}')
    debug "Current CPU usage: $CPU_USAGE%"
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
        -d|--debug)
            DEBUG_MODE=true
            shift
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

# Enable trace mode for debugging
if [ "$DEBUG_MODE" = true ]; then
    set -x
fi


read -p "Please enter your name: " USER_NAME
read -p "Please enter your age: " USER_AGE
read -p "Please enter your country: " USER_COUNTRY


if ! [[ "$USER_AGE" =~ ^[0-9]+$ ]] || [ "$USER_AGE" -lt 18 ] || [ "$USER_AGE" -gt 60 ]; then
    echo "Error: Age must be a numeric value between 18 and 60."
    exit 1
fi

echo "Hello, $USER_NAME from $USER_COUNTRY! You are $USER_AGE years old."


if [ -f "$LOG_FILE" ]; then

    monitor_cpu  # Monitor CPU usage
    

    if [ ! -d "$BACKUP_DIR" ]; then
        mkdir -p "$BACKUP_DIR"
        debug "Created backup directory: $BACKUP_DIR"
    fi


    TIMESTAMP=$(date +'%Y%m%d%H%M%S')
    BACKUP_FILE="$BACKUP_DIR/messages.$TIMESTAMP"
    
    # Use rsync for efficient file copying
    debug "Copying $LOG_FILE to $BACKUP_FILE..."
    rsync --inplace --no-whole-file "$LOG_FILE" "$BACKUP_FILE"
    
    if [ $? -eq 0 ]; then
        echo "[$USER_NAME] Successfully copied $LOG_FILE to $BACKUP_FILE."
    else
        echo "[$USER_NAME] Error: Failed to copy $LOG_FILE to $BACKUP_FILE."
        exit 1
    fi

    monitor_cpu  # Monitor CPU usage

    # Clear the log file efficiently
    debug "Clearing the contents of $LOG_FILE..."
    cat /dev/null > "$LOG_FILE"

    if [ $? -eq 0 ]; then
        echo "[$USER_NAME] Successfully cleared the contents of $LOG_FILE."
    else
        echo "[$USER_NAME] Error: Failed to clear the contents of $LOG_FILE."
        exit 1
    fi

    monitor_cpu  # Monitor CPU usage

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

    monitor_cpu  # Monitor CPU usage

    # Rotate backups and retain only the last $MAX_BACKUPS
    BACKUP_COUNT=$(ls -1q "$BACKUP_DIR/messages."* | wc -l)
    if [ "$BACKUP_COUNT" -gt "$MAX_BACKUPS" ]; then
        # Delete older backups
        REMOVE_COUNT=$((BACKUP_COUNT - MAX_BACKUPS))
        echo "[$USER_NAME] Removing $REMOVE_COUNT old backup(s)..."
        ls -1t "$BACKUP_DIR/messages."* | tail -n "$REMOVE_COUNT" | xargs rm -f
    fi
else
    echo "[$USER_NAME] Error: $LOG_FILE does not exist."
    exit 1
fi

# Disable trace mode after debugging
if [ "$DEBUG_MODE" = true ]; then
    set +x
fi
