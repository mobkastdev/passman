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
	for ((i=0; i<${#array[@]}; i++)); do
	    echo "$(($i+1))) ${array[i]}"
	done
	read siteselect
	
        # BUG: Only works with display all, if individual search is done, it does not work
        objectInfo=$(grep -A3 "^id: $(($siteselect-1))" <<< "$inputStream")
        objectInfoLineNumber=$(awk -v select="id: $(($siteselect-1))" '$0~select{print NR}' <<< "$inputStream")
        previousSite=$(awk '/^site: / {$1=""; print substr($0,2)}' <<< "$objectInfo")
        previousUser=$(awk '/^user: / {$1=""; print substr($0,2)}' <<< "$objectInfo")
        previousPass=$(awk '/^pass: / {$1=""; print substr($0,2)}' <<< "$objectInfo")

        select interactoption in "copy info" "list metadata" "edit" "delete" "exit"
	do 
	    case $interactoption in

	    "copy info")
	    # Selects the site to copy and copies the username to clipboard 
	    # (pbcopy only works on mac)
            pbcopy <<< "$previousUser"

	    echo "Username copied!"
	    echo "Press enter when you would like to copy the password..."
	    read

	    # Copies the password to clipboard	
            pbcopy <<< "$previousPass"
	    echo "Password copied!"
	    ;;

	    "list metadata")
                echo "site: $previousSite"
                echo "user: $previousUser"
                echo "pass: $previousPass"
	    ;;

	    edit)
                echo "Site Name ($previousSite):"
	        read sname
                echo "Username ($previousUser):"
	        read uname
                echo "Password: ($previousPass)"	
	        read -s pass

                if [[ -n $sname ]]; then
                    inputStream=$(sed "$(($objectInfoLineNumber+1))s/$previousSite/$sname/g" <<< "$inputStream")
                fi
                
                if [[ -n $uname ]]; then
                    inputStream=$(sed "$(($objectInfoLineNumber+2))s/$previousUser/$uname/g" <<< "$inputStream")
                fi

                if [[ -n $pass ]]; then
                    inputStream=$(sed "$(($objectInfoLineNumber+3))s/$previousPass/$pass/g" <<< "$inputStream")
                fi

                # Add this to a function
        objectInfo=$(grep -A3 "^id: $(($siteselect-1))" <<< "$inputStream")
        previousSite=$(awk '/^site: / {$1=""; print substr($0,2)}' <<< "$objectInfo")
        previousUser=$(awk '/^user: / {$1=""; print substr($0,2)}' <<< "$objectInfo")
        previousPass=$(awk '/^pass: / {$1=""; print substr($0,2)}' <<< "$objectInfo")
                echo 
                echo "Account successfully updated!"
	    ;;

	    delete)
                inputStream=$(sed "$(($objectInfoLineNumber)),$(($objectInfoLineNumber+5))" <<< "$inputStream")

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
