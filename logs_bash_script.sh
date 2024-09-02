#!/bin/bash


LOG_FILE="/var/log/messages"
BACKUP_FILE="/var/log/messages.old"


if [ -f "$LOG_FILE" ]; then
   
    cp "$LOG_FILE" "$BACKUP_FILE"
    
   
    if [ $? -eq 0 ]; then
        echo "Successfully copied $LOG_FILE to $BACKUP_FILE."
    else
        echo "Error: Failed to copy $LOG_FILE to $BACKUP_FILE."
        exit 1
    fi

   
    : > "$LOG_FILE"  

    
    if [ $? -eq 0 ]; then
        echo "Successfully cleared the contents of $LOG_FILE."
    else
        echo "Error: Failed to clear the contents of $LOG_FILE."
        exit 1
    fi
else
    echo "Error: $LOG_FILE does not exist."
    exit 1
fi

