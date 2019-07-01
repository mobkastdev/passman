#!/bin/bash

declare -i siteOccurance="0"
declare -i siteChoice="0"
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

echo

if [ $? -ne 0 ]; then
    echo "Incorrect password!"
    exit 1
fi

#^D is not captured and so will not display messages

trap "pbcopy < /dev/null; echo -e \ No changes saved!; exit 0" INT
trap "pbcopy < /dev/null; echo -e \ No changes saved!; exit 0" SIGINT
trap "pbcopy < /dev/null; echo -e \ No changes saved!; exit 0" SIGTSTP
trap "pbcopy < /dev/null; echo -e \ No changes saved!; exit 0" SIGTERM

# Bypass interactive system
if [ "$#" -gt 0 ]; then
    singleObjectLineNumber=$(awk -v select="^site: $1$" 'tolower($0)~select{print NR}' <<< "$inputStream")

if [ -n "$singleObjectLineNumber" ]; then
    if [[ $(wc -l <<< "$singleObjectLineNumber") -gt 1 ]]; then
        echo "Error: Multiple sitenames detected, use passman with no arguments to retrieve multiple accounts of the same sitename"
        exit 1
    else
        singleObjectPass=$(awk -v lineNumber="$(($singleObjectLineNumber+2))" 'lineNumber==NR {$1=""; print substr($0,2)}' <<< "$inputStream")
        pbcopy <<< "$singleObjectPass"
        echo "Password copied! (Password is cleared after 20 seconds/when program is exited/when enter is pressed)..."
        (sleep 20; pbcopy < /dev/null) & 
        read
        pbcopy < /dev/null
        echo "Password cleared!"
        exit 0
    fi
else
    echo "Site $1 is not found"
    exit 1
fi
fi

select viewOption in "list" "add" "exit"
do
    case $viewOption in
	
        list)
	echo "Enter the sitename:"
	read -e sname		

        # Choose account by the site
	while read -er result; do
        # Sort duplicate array values
            if [[ ! " ${selectedSiteArray[@]} " =~ " ${result} " ]]; then
	        selectedSiteArray+=("$result") 
            else
                duplicateSiteNameArray+=("$result")
            fi
        done < <(awk -v name="site: $sname" 'tolower($0)~name{$1=""; print substr($0,2)}' <<< "$inputStream")

        while [ " ${#selectedSiteArray[@]} " -eq 0 ]; do
        echo "No results found. Please try again"
	echo "Enter the sitename:"
	read -e sname		
        while read -er result; do
            if [[ ! " ${selectedSiteArray[@]} " =~ " ${result} " ]]; then
	        selectedSiteArray+=("$result") 
            else
                duplicateSiteNameArray+=("$result")
            fi
        done < <(awk -v name="site: $sname" 'tolower($0)~name{$1=""; print substr($0,2)}' <<< "$inputStream")
        done
        echo "${selectedSiteArray[@]}"
        echo "Select sitename to copy username:"
        ((dupSiteCount=0))
      	        for ((i=0; i<${#selectedSiteArray[@]}; i++)); do
                    for dupSite in "${duplicateSiteNameArray[@]}"; do
                    if [ "${selectedSiteArray[$i]}" = "$dupSite" ]; then
                        ((dupSiteCount++)) 
                    fi
                done
                    if [ "$dupSiteCount" -gt 0 ]; then
                        echo "$(($i+1))) "${selectedSiteArray[$i]}" ($(($dupSiteCount+1)))"
                    else
                        echo "$(($i+1))) "${selectedSiteArray[$i]}""
                    fi
                ((dupSiteCount=0))
            done
                read -ep '#? ' siteChoice

            while [ $siteChoice -le 0 ] || [ $siteChoice -gt "${#selectedSiteArray[@]}" ]; do
                echo "Error: Pick a valid number from the list:"
      	        for ((i=0; i<${#selectedSiteArray[@]}; i++)); do
                    for dupSite in "${duplicateSiteNameArray[@]}"; do
                    if [ "${selectedSiteArray[$i]}" = "$dupSite" ]; then
                        ((dupSiteCount++)) 
                    fi
                done
                    if [ "$dupSiteCount" -gt 0 ]; then
                        echo "$(($i+1))) "${selectedSiteArray[$i]}" ($(($dupSiteCount+1)))"
                    else
                        echo "$(($i+1))) "${selectedSiteArray[$i]}""
                    fi
                ((dupSiteCount=0))
            done
            read -ep '#? ' siteChoice
            done
        
            siteSelect=${selectedSiteArray[$(($siteChoice-1))]}

            singleObjectLineNumber=$(awk -v select="^site: $siteSelect$" 'tolower($0)~select{print NR}' <<< "$inputStream")

        while read -er result; do
            objectLineNumber+=("$result") 
        done < <(echo "$singleObjectLineNumber")

        if [ ${#objectLineNumber[@]} -gt 1 ]; then
            echo "Duplicate site detected, select login associated with the site: $siteSelect"
      	    for ((i=0; i<${#objectLineNumber[@]}; i++)); do
                echo "$(($i+1))) $(awk -v range="$((${objectLineNumber[$i]}+1))" 'range==NR {print $2}' <<< "$inputStream")"
	    done
	    read -ep '?# ' siteOccurance

            while [ $siteOccurance -le 0 ] || [ $siteOccurance -gt "${#objectLineNumber[@]}" ]; do
                echo
                echo "Duplicate site detected, select login associated with the site: $siteSelect"
      	        for ((i=0; i<${#objectLineNumber[@]}; i++)); do
                echo "$(($i+1))) $(awk -v range="$((${objectLineNumber[$i]}+1))" 'range==NR {print $2}' <<< "$inputStream")"
                done
	        read -ep '#? ' siteOccurance
            done

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
            echo "Password copied! (Password is cleared after 20 seconds/when program is exited/when enter is pressed)..."
            (sleep 20; pbcopy < /dev/null) & 
            read
            pbcopy < /dev/null
            echo "Password cleared!"
	    ;;

	    "list metadata")
                echo "site: $currentSite"
                echo "user: $currentUser"
                echo "tags: $(sed -e 's/^/#&/' -e 's/ / #/g' <<< $currentTags)"
                # Newlines do not work in Mac OSX https://stackoverflow.com/questions/723157/how-to-insert-a-newline-in-front-of-a-pattern
                echo "note: $(sed 's/;/\
      /' <<< $currentNote)"
	    ;;

	    edit)
                echo "Site Name ($currentSite):"
	        read -e sname
                echo "Username ($currentUser):"
	        read -e uname
                echo "Password:"	
	        read -s pass
                echo "Tags: [Separate fields by semicolons] ($currentTags)"
                read -e tags
                echo "Note: [Separate fields by semicolons] ($currentNote)"
                read -e note

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
;;
	add)
	echo "Site Name:"
	read -e sname
	echo "Username:"
	read -e uname
	echo "Password:"	
	read -s pass
        echo "Tags [Separate fields with spaces]:"
        read -e tags
        echo "Note [Separate fields with semicolons]:"
        read -e note
        
	inputStream+=$"

        site: $(echo $sname | tr '[:upper:]' '[:lower:]')"
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
            echo "Account information saved!"
            exit 0
        ;; 
	esac
done
