#!/bin/bash

declare -a selectedSiteArray
declare -a duplicateSiteNameArray
declare -a objectLineNumber

function Refresh_Object_Credentials {
        singleObjectInfo=$(sed "$singleObjectLineNumber,$(($singleObjectLineNumber+3))!d" <<< "$inputStream")
        currentSite=$(awk '/^site: / {$1=""; print substr($0,2)}' <<< "$singleObjectInfo")
        currentUser=$(awk '/^user: / {$1=""; print substr($0,2)}' <<< "$singleObjectInfo")
        currentPass=$(awk '/^pass: / {$1=""; print substr($0,2)}' <<< "$singleObjectInfo")
}

echo "Password:"
read -s masterpass

# Decrypt file
inputStream=$(openssl enc -d -aes-256-cbc -in ~/passwords.enc -pass pass:$masterpass 2> /dev/null)

if [ $? -ne 0 ]; then
    echo "Incorrect password!"
    exit 1
fi

# Reverse grep search for the first occurance of "id"
id=$(sed '1!G;h;$!d' <<< "$inputStream" | grep -m 1 "id: " | awk '{print $2}')

select viewOption in "list" "add" "exit"
do
    case $viewOption in
	
        list)
	echo "Enter the sitename:"
	read sname		

        # Choose account by the site
	while read -r results; do
	    selectedSiteArray+=("$results") 
	done < <(awk -v name="site: $sname" '$0~name{$1=""; print substr($0,2)}' <<< "$inputStream")

	echo "Select sitename to copy username:"
        select siteSelect in "${selectedSiteArray[@]}"
        do

        singleObjectLineNumber=$(awk -v select="site: $siteSelect" '$0~select{print NR-1}' <<< "$inputStream")

        while read -r results; do
            objectLineNumber+=("$results") 
        done < <(echo "$singleObjectLineNumber")

#echo "${singleObjectLineNumber[@]}"
#echo "${objectLineNumber[@]}"

        # Filter duplicate site values
	while read -r site; do
	    duplicateSiteNameArray+=("$site") 
	done < <(printf '%s\n' "${selectedSiteArray[@]}" | awk -v siteName="^$siteSelect$" '$0~siteName')

        if [ ${#duplicateSiteNameArray[@]} -gt 1 ]; then
            echo "Duplicate site detected, select login associated with the site: $siteSelect"
      	    for ((i=0; i<${#duplicateSiteNameArray[@]}; i++)); do
                echo "$(($i+1))) $(awk -v range="$((${objectLineNumber[$i]}+2))" 'range==NR {print $2}' <<< "$inputStream")"
	    done
	    read siteOccurance

            singleObjectLineNumber=$(awk -v occurance="$siteOccurance" 'occurance==NR' <<< "$singleObjectLineNumber")
        fi
        

        Refresh_Object_Credentials

        select interactOption in "copy info" "list metadata" "edit" "delete" "exit"
	do 
	    case $interactOption in

	    "copy info")
	    # Selects the site to copy and copies the username to clipboard 
	    # (pbcopy only works on mac)
            pbcopy <<< "$currentUser"

	    echo "Username copied!"
	    echo "Press enter when you would like to copy the password..."
	    read

	    # Copies the password to clipboard	
            pbcopy <<< "$currentPass"
	    echo "Password copied!"
	    ;;

	    "list metadata")
                echo "site: $currentSite"
                echo "user: $currentUser"
                echo "pass: $currentPass"
	    ;;

	    edit)
                echo "Site Name ($currentSite):"
	        read sname
                echo "Username ($currentUser):"
	        read uname
                echo "Password: ($currentPass)"	
	        read -s pass

                # Check if null
                if [[ -n $sname ]]; then
                    inputStream=$(sed "$(($singleObjectLineNumber+1))s/$currentSite/$sname/g" <<< "$inputStream")
                fi
                
                if [[ -n $uname ]]; then
                    inputStream=$(sed "$(($singleObjectLineNumber+2))s/$currentUser/$uname/g" <<< "$inputStream")
                fi

                if [[ -n $pass ]]; then
                    inputStream=$(sed "$(($singleObjectLineNumber+3))s/$currentPass/$pass/g" <<< "$inputStream")
                fi

                Refresh_Object_Credentials
                echo 
                echo "Account successfully updated!"
	    ;;

	    delete)
                inputStream=$(echo "$inputStream" | sed "$singleObjectLineNumber,$((${singleObjectLineNumber}+4))d")

                echo 
                echo "Account successfully deleted!"
                echo "$inputStream"
                break
	    ;;
					
	    exit)
	    break
	    ;;
	    esac
        done

	selectedSiteArray=()
        duplicateSiteNameArray=()
        break
done
;;
	add)
	echo "Site Name:"
	read sname
	echo "Username:"
	read uname
	echo "Password:"	
	read -s pass
        
        # Need to fix ugly spaces
	inputStream+=$"

site: $sname"
	inputStream+=$"
user: $uname"
	inputStream+=$"
pass: $pass"

        echo "Site $sname successfully added!"
	;;

	exit) 
            # Encrypt file
            openssl enc -aes-256-cbc -salt -out ~/passwords.enc -pass pass:$masterpass <<< "$inputStream"
            exit 0
        ;; 
	esac
done
