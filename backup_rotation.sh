#!/bin/bash

LOG_FILE="/var/log/messages"
BACKUP_DIR="/var/log/backup"
MAX_BACKUPS=5

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
