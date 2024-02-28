#!/bin/sh
###############################################################################################################
# Author: Jason Johnson
# Date: Nov 06, 2023
# Purpose: Transfers files in the outbound directory to remote host, controlled by a cron job     
###############################################################################################################
# Modification History
# 20231207 JKJ: add more error checking for failed transfers
# 20240228 JKJ: This script was original build for a specific usecase, but i've stripped out some of the sensitive data to use as a reference
###############################################################################################################

log_dir=/home/user/logs
log_file="$(date +'%Y%m%d_%H%M')_d375_move.log"
cleanup_dir=/home/user/logs/cleanup
cleanup_log="$(date +'%Y%m%d_%H%M')_d375_cleanup.log"
sent_dir="/data/user/outbound/.sent"
failed_transfer=0 #Initalize the variable for transfer failure check

shopt -s nullglob

echo -e "Start: $(date)\n" > $log_dir/$log_file

cd /data/user/outbound

# if a file exists here, start the transfer process, if not just log that there are no files to transfer
if [ "$(find . -maxdepth 1 -mindepth 1 -type f)" ]; then
   for i in *
   do
      scp -C -o LogLevel=Error -i /home/user/.ssh/id_rsa $i user@remotehost.domain.com:/remote/dir >> $log_dir/$log_file 2>&1
      # if the previous scp command succeeds then we'll log the success, move the file to the .sent directory and change permissions on the remote side
      # otherwise set the failed_transfer flag to 1 so we can alert via email
      if [ $? -eq 0 ];
      then
        echo -e "SUCCEEDED Transfer of: "$i" \n" >> $log_dir/$log_file
        mv $i .sent
        ssh -o LogLevel=Error -i /home/user/.ssh/id_rsa user@remotehost.domain.com "cd /remote/dir/ftp && chmod 660 $i" >> $log_dir/$log_file 2>&1
      else
        echo -e "FAILED Transfer of "$i" \n" >> $log_dir/$log_file
        failed_transfer=1
      fi
        sleep 2s
   done
else
   echo "Found no files to transfer" >> $log_dir/$log_file
fi

echo -e "\nFinished: $(date)" >> $log_dir/$log_file

if [ "$failed_transfer" -eq 1 ]; then
        (
        echo "From: fromuser@mail.com"
        echo "To: recipients@mail.com recipient2@mail.com"
        echo "Subject: Some Failed Transfers"
        echo ""
        echo "Contents of $log_file"
        cat "$log_dir/$log_file"
        echo -e "\nRestore linebreaks for easier reading"
        echo -e "This filetransfer is ran out of the ftp server.\n Check the user home dir for more information"
        ) | /usr/sbin/sendmail -t 2>/dev/null
fi


# Log and File Cleanup
echo "Deletions on $(date):" >> $cleanup_dir/$cleanup_log
echo "Logs deleted:" >> $cleanup_dir/$cleanup_log
find "$log_dir" -type f -mtime +30 -exec echo {} \; -exec rm {} \; >> $cleanup_dir/$cleanup_log
echo "Files in .sent directory deleted:" >> $cleanup_dir/$cleanup_log
find "$sent_dir" -type f -mtime +30 -exec echo {} \; -exec rm {} \; >> $cleanup_dir/$cleanup_log
