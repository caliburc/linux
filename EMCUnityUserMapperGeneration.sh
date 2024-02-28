#!/bin/bash
#######################################################################################
# Purpose: Create a file can be used in the EMC Unity usermapper
# Description:
# This script query's IPA for all users who have a employeenumber set
# then splits that information into a file with just the username and edipi
# then it reads that file and generates a new usermapper formatted file
# ex.
# AREA52:1165077764*:>:jason.johnson.adm
# AREA52:1165077764.ADF:<:jason.johnson.adm
# this assumes that any AD user with that edipi (user or admin) will map to a 
# single linux side user. When a file is created on the linux side
# it is then mapped to the matching ADF account - which we are assuming exists.
#
# You will need to take the date formatted usermapper.txt file, and place that into
# the usermapper file you can download from the Unity NAS Servers.
########################################################################################


read -p "Enter LDAP IPA Username: " binduser

ldapsearch='ldapsearch -x -H ldap://apipa1p.infra.hedc -D "uid=${binduser},cn=users,cn=accounts,dc=infra,dc=hedc" -W -b "cn=users,cn=accounts,dc=infra,dc=hedc" "(&(objectClass=person)(employeenumber=*))" uid employeeNumber'

date=$(date +"%Y%m%d")
edipi_output_file="${date}_rhel6_adm_edipis.txt"
> "$edipi_output_file"

output=$(eval $ldapsearch)

while IFS= read -r line; do
        if [[ $line == "uid: "* ]]; then
        uid=${line#uid: }
        elif [[ $line == "employeeNumber: "* ]]; then
        employeeNumber=${line#employeeNumber: }
        echo "$uid $employeeNumber" >> "$edipi_output_file"
        fi
done <<< "$output"
echo "Wrote Admin EDIPI's to ${edipi_output_file}"


usermapper_output_file="${date}_usermapper.txt"
> "$usermapper_output_file"

# Loop over each line in the "users" file
while read line; do
    # Split the line into "username" and "edipi"
    username=$(echo $line | cut -d' ' -f1)
    edipi=$(echo $line | cut -d' ' -f2)
    # Write the formatted output to the "usermapper_output_file" file
    echo "AREA52:${edipi}*:>:$username" >> $usermapper_output_file
    echo "AREA52:${edipi}.ADF:<:$username" >> $usermapper_output_file
done <  $edipi_output_file

echo "Created new usermapper file ${user_mapper_output_file}"
