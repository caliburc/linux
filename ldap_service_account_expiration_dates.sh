#!/bin/bash
#######################################################################################
# Purpose: Get expiration date of service accounts
# Description: 
# Queries LDAP for any account in the "service_account" group and pulls their password
# expiration date, writes to file.
# 
########################################################################################


read -p "Enter LDAP IPA Username: " binduser

ldapsearch='ldapsearch -x -H ldap://apipa1p.infra.hedc -D "uid=${binduser},cn=users,cn=accounts,dc=infra,dc=hedc" -W -b "cn=users,cn=accounts,dc=infra,dc=hedc" "(&(objectClass=top)(memberOf=*service_account*))" uid krbPasswordExpiration'

date=$(date +"%Y%m%d")
service_accounts_expiration_file="${date}_service_accounts_expirations.txt"
> "$edipi_output_file"

output=$(eval $ldapsearch)

while IFS= read -r line; do
        if [[ $line == "uid: "* ]]; then
        uid=${line#uid: }
        elif [[ $line == "krbPasswordExpiration: "* ]]; then
        expirationdate=${line#krbPasswordExpiration: }
        echo "$uid $expirationdate" >> "$service_account_expiration_file"
        fi
done <<< "$output"
echo "Wrote Admin EDIPI's to ${service_account_expiration_file}"

