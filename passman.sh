#!/bin/bash

declare -a selectedSiteArray
declare -a duplicateSiteNameArray
declare -a objectLineNumber

function Refresh_Object_Credentials {
        singleObjectInfo=$(sed "$singleObjectLineNumber,$(($singleObjectLineNumber+5))!d" <<< "$inputStream")
        currentSite=$(awk '/^site: / {$1=""; print substr($0,2)}' <<< "$singleObjectInfo")
        currentUser=$(awk '/^user: / {$1=""; print substr($0,2)}' <<< "$singleObjectInfo")
        currentPass=$(awk '/^pass: / {$1=""; print substr($0,2)}' <<< "$singleObjectInfo")
        currentTags=$(awk '/^tags: / {$1=""; print substr($0,2)}' <<< "$singleObjectInfo")
        currentNote=$(awk '/^note: / {$1=""; print substr($0,2)}' <<< "$singleObjectInfo")
}

echo "Password:"
read -s masterpass

# Decrypt file
inputStream=$(openssl enc -d -aes-256-cbc -in ~/passwords.enc -pass pass:$masterpass 2> /dev/null)

if [ $? -ne 0 ]; then
    echo "Incorrect password!"
    exit 1
fi

select viewOption in "list" "add" "exit"
do
    case $viewOption in
	
        list)
	echo "Enter the sitename:"
	read -e sname		

        # Choose account by the site
	while read -e -r result; do
        # Sort duplicate array values
        # TODO: Add a physical mark to notify the user that that site has a duplicate entry
            if [[ ! " ${selectedSiteArray[@]} " =~ " ${result} " ]]; then
	        selectedSiteArray+=("$result") 
            else
                duplicateSiteNameArray+=("$result")
            fi
	done < <(awk -v name="site: $sname" '$0~name{$1=""; print substr($0,2)}' <<< "$inputStream")

        echo "Select sitename to copy username:"
        select siteSelect in "${selectedSiteArray[@]}"
        do

        singleObjectLineNumber=$(awk -v select="^site: $siteSelect$" '$0~select{print NR}' <<< "$inputStream")

        while read -e -r result; do
            objectLineNumber+=("$result") 
        done < <(echo "$singleObjectLineNumber")

        if [ ${#duplicateSiteNameArray[@]} -gt 0 ]; then
            echo "Duplicate site detected, select login associated with the site: $siteSelect"
      	    for ((i=0; i<${#objectLineNumber[@]}; i++)); do
                echo "$(($i+1))) $(awk -v range="$((${objectLineNumber[$i]}+2))" 'range==NR {print $2}' <<< "$inputStream")"
	    done
	    read -e siteOccurance

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
	    read -e

	    # Copies the password to clipboard	
            pbcopy <<< "$currentPass"
	    echo "Password copied!"
	    ;;

	    "list metadata")
                echo "site: $currentSite"
                echo "user: $currentUser"
                echo "tags: $currentTags"
                echo "note: $currentNote"
	    ;;

	    edit)
                echo "Site Name ($currentSite):"
	        read -e sname
                echo "Username ($currentUser):"
	        read -e uname
                echo "Password:"	
	        read -s pass
                echo "Tags: ($currentTags)"
                read -e tags
                echo "Note: ($currentNote)"
                read -e note

                echo "$singleObjectLineNumber"

                # Check if null
                if [[ -n $sname ]]; then
                    inputStream=$(sed "$(($singleObjectLineNumber))s/$currentSite/$sname/g" <<< "$inputStream")
                fi
                
                if [[ -n $uname ]]; then
                    inputStream=$(sed "$(($singleObjectLineNumber+1))s/$currentUser/$uname/g" <<< "$inputStream")
                fi

                if [[ -n $pass ]]; then
                    inputStream=$(sed "$(($singleObjectLineNumber+2))s/$currentPass/$pass/g" <<< "$inputStream")
                fi

                if [[ -n $tags ]]; then
                    inputStream=$(sed "$(($singleObjectLineNumber+3))s/$currentTags/$tags/g" <<< "$inputStream")
                fi

                if [[ -n $note ]]; then
                    inputStream=$(sed "$(($singleObjectLineNumber+4))s/$currentNote/$note/g" <<< "$inputStream")
                fi

                Refresh_Object_Credentials

                echo 
                echo "Account successfully updated!"
	    ;;

	    delete)
                inputStream=$(echo "$inputStream" | sed "$singleObjectLineNumber,$((${singleObjectLineNumber}+5))d")

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
        objectLineNumber=()
        break
done
;;
	add)
	echo "Site Name:"
	read -e sname
	echo "Username:"
	read -e uname
	echo "Password:"	
	read -s pass
        echo "Tags:"
        read -e tags
        echo "Note:"
        read -e note
        
        # Need to fix ugly spaces
	inputStream+=$"

site: $sname"
	inputStream+=$"
user: $uname"
	inputStream+=$"
pass: $pass"
        inputStream+=$"
tags: $tags"
        inputStream+=$"
note: $note
"

        echo "Site $sname successfully added!"
	;;

	exit) 
            # Encrypt file
            openssl enc -aes-256-cbc -salt -out ~/passwords.enc -pass pass:$masterpass <<< "$inputStream"
            exit 0
        ;; 
	esac
done
