#!/bin/bash

LOG_FILE="/var/log/messages"
BACKUP_FILE="/var/log/messages.old"


read -p "Please enter your name: " USER_NAME
read -p "Please enter your age: " USER_AGE
read -p "Please enter your country: " USER_COUNTRY


if ! [[ "$USER_AGE" =~ ^[0-9]+$ ]] || [ "$USER_AGE" -lt 0 ] || [ "$USER_AGE" -gt 120 ]; then
    echo "Error: Age must be a numeric value between 0 and 120."
    exit 1
fi

echo "Hello, $USER_NAME from $USER_COUNTRY! You are $USER_AGE years old."

if [ -f "$LOG_FILE" ]; then
   

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
else
    echo "[$USER_NAME] Error: $LOG_FILE does not exist."
    exit 1
fi
