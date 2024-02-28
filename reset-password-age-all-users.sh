#!/bin/bash

# DON'T USE THIS UNLESS YOU KNOW WHAT YOU ARE DOING #

usernames=$(cut -d: -f1 /etc/passwd)

today=$(date +%F)

for username in $usernames; do
    chage "$username" -d $today -M 365 -I -1
    set_date=$(chage -l "$username" | grep "Last password change" | awk -F': ' '{print $2}')
    expiration=$(chage -l "$username" | grep "Password expires" | awk -F': ' '{print $2}')
    echo "User:$username - Set Date:${set_date}, Expiration Date:$expiration"
done
