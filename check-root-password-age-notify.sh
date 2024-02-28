#!/bin/bash

recipient=touser@mail.com"
subject="RHEL7 Root Password Expiration Notice"

send_email() {
    local body="$1"
    sendmail -t <<EOF
To: $recipient
From: user@email.com
Subject: $subject

$body
.
EOF
}


root_expire_date=$(chage -l root | grep "Password expires" | awk -F': ' '{print $2}')
root_expire_formatted=$(date -d "$root_expire_date" +"%Y-%m-%d")
current_formatted=$(date +"%Y-%m-%d")
days_diff=$(( ($(date -d "$root_expire_formatted" +%s) - $(date -d "$current_formatted" +%s)) / 86400 ))

if [ $days_diff -lt 0 ]; then
    echo "Password Expired - Sending Email"
    body="The Root Password on aphedc0p has expired!!  Change immediately and check the rest of the environment!"
    send_email "$body"
elif [ $days_diff -eq 0 ]; then
    echo "Passowrd Expiring today - Sending Email"
    body="Password will expire today! Change immediately and check the rest of the environment!"
    send_email "$body"
elif [ $days_diff -le 5 ]; then
    echo "Password expires in $days_diff days. - Sending Email"
    body="The Root Password on aphedc0p will expire in $days_diff days.
    Please change the password soon and check the rest of the environment."
    send_email "$body"
fi


