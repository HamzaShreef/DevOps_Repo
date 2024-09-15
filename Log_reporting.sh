#!/bin/bash

LOG_FILE="/var/log/messages"
BACKUP_DIR="/var/log/backup"
MAX_BACKUPS=2
ANALYSIS_REPORT="$BACKUP_DIR/log_analysis_report.txt"


read -p "Please enter your name: " USER_NAME
read -p "Please enter your age: " USER_AGE
read -p "Please enter your country: " USER_COUNTRY


if ! [[ "$USER_AGE" =~ ^[0-9]+$ ]] || [ "$USER_AGE" -lt 18 ] || [ "$USER_AGE" -gt 60 ]; then
    echo "Error: Age must be a numeric value between 18 and 60."
    exit 1
fi

echo "Hello, $USER_NAME from $USER_COUNTRY! You are $USER_AGE years old."

if [ -f "$LOG_FILE" ]; then
   
    if [ ! -d "$BACKUP_DIR" ]; then
        mkdir -p "$BACKUP_DIR"
        echo "Created backup directory: $BACKUP_DIR"
    fi

    TIMESTAMP=$(date +'%Y%m%d%H%M%S')
    BACKUP_FILE="$BACKUP_DIR/messages.$TIMESTAMP"
    cp "$LOG_FILE" "$BACKUP_FILE"
    
    if [ $? -eq 0 ]; then
        echo "[$USER_NAME] Successfully copied $LOG_FILE to $BACKUP_FILE."
    else
        echo "[$USER_NAME] Error: Failed to copy $LOG_FILE to $BACKUP_FILE."
        exit 1
    fi

    : > "$LOG_FILE"  

    if [ $? -eq 0 ]; then
        echo "[$USER_NAME] Successfully cleared the contents of $LOG_FILE."
    else
        echo "[$USER_NAME] Error: Failed to clear the contents of $LOG_FILE."
        exit 1
    fi

    # Analyze the copied log file and generate a report
    ERROR_COUNT=$(grep -i "error" "$BACKUP_FILE" | wc -l)
    WARNING_COUNT=$(grep -i "warning" "$BACKUP_FILE" | wc -l)
    CRITICAL_COUNT=$(grep -i "critical" "$BACKUP_FILE" | wc -l)

    echo "[$USER_NAME] Generating log analysis report..."
    {
        echo "Log Analysis Report - $TIMESTAMP"
        echo "================================="
        echo "Log File: $BACKUP_FILE"
        echo "Error Count: $ERROR_COUNT"
        echo "Warning Count: $WARNING_COUNT"
        echo "Critical Count: $CRITICAL_COUNT"
        echo "================================="
    } > "$ANALYSIS_REPORT"

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
