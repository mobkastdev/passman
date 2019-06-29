#!/bin/bash

echo "Password:"
read -s masterpass

# Decrypt file
inputStream=$(openssl enc -d -aes-256-cbc -in ~/passwords.enc -pass pass:$masterpass 2> /dev/null)

if [ $? -ne 0 ]; then
    echo "Incorrect password!"
    exit 1
fi

declare -a array
# Reverse grep search for the first occurance of "id"
id=$(sed '1!G;h;$!d' <<< "$inputStream" | grep -m 1 "id: " | awk '{print $2}')

select viewoption in "list" "add" "exit"
do
    case $viewoption in
	
        list)
	echo "Enter the sitename:"
	read sname		

	while read -r results; do
	    array+=("$results") 
	# make variable and check regex here
	done < <(awk -v name="site: $sname" '$0~name{$1=""; print substr($0,2)}' <<< "$inputStream")

	echo "Select sitename to copy username:"
        select siteSelect in "${array[@]}"
        do
	
        objectInfoLineNumber=$(awk -v select="site: $siteSelect" '$0==select{print NR-1}' <<< "$inputStream")
        singleObjectInfo=$(sed "$objectInfoLineNumber,$(($objectInfoLineNumber+3))!d" <<< "$inputStream")
        currentSite=$(awk '/^site: / {$1=""; print substr($0,2)}' <<< "$singleObjectInfo")
        currentUser=$(awk '/^user: / {$1=""; print substr($0,2)}' <<< "$singleObjectInfo")
        currentPass=$(awk '/^pass: / {$1=""; print substr($0,2)}' <<< "$singleObjectInfo")
        select interactoption in "copy info" "list metadata" "edit" "delete" "exit"
	do 
	    case $interactoption in

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
                    inputStream=$(sed "$(($objectInfoLineNumber+1))s/$currentSite/$sname/g" <<< "$inputStream")
                fi
                
                if [[ -n $uname ]]; then
                    inputStream=$(sed "$(($objectInfoLineNumber+2))s/$currentUser/$uname/g" <<< "$inputStream")
                fi

                if [[ -n $pass ]]; then
                    inputStream=$(sed "$(($objectInfoLineNumber+3))s/$currentPass/$pass/g" <<< "$inputStream")
                fi

                # Add this to a function
                # Update metadata
        singleObjectInfo=$(sed "$objectInfoLineNumber,$(($objectInfoLineNumber+4))!d" <<< "$inputStream")
        currentSite=$(awk '/^site: / {$1=""; print substr($0,2)}' <<< "$singleObjectInfo")
        currentUser=$(awk '/^user: / {$1=""; print substr($0,2)}' <<< "$singleObjectInfo")
        currentPass=$(awk '/^pass: / {$1=""; print substr($0,2)}' <<< "$singleObjectInfo")
                echo 
                echo "Account successfully updated!"
	    ;;

	    delete)
                inputStream=$(sed "$objectInfoLineNumber,$(($objectInfoLineNumber+5))" <<< "$inputStream")

                #Add function here
                echo 
                echo "Account successfully deleted!"
	    ;;
					
	    exit)
	    break
	    ;;
	    esac
        done

	array=()
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
	echo "id: $(($id + 1))" >> $inputStream 
	echo "site: $sname" >> $inputStream
	echo "user: $uname" >> $inputStream
	echo "pass: $pass" >> $inputStream
	echo " " >> $inputStream
	;;

	exit) 
            # Encrypt file
            openssl enc -aes-256-cbc -salt -out ~/passwords.enc -pass pass:$masterpass <<< "$inputStream"
            exit 0
        ;; 
	esac
done
