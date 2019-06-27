#!/bin/bash
declare -a array
# Reverse grep search for the first occurance of "id"
id=$(sed '1!G;h;$!d' ~/passwords.txt | grep -m 1 "id: " | awk '{print $2}')
#if [su $(whoami)] then


select viewoption in "list" "add" "exit"
do
    case $viewoption in
	
        list)
	echo "Enter the sitename:"
	read sname		

	while read -r results; do
	    array+=("$results") 
	# make variable and check regex here
	done < <(awk -v name="site: $sname" '$0~name{$1=""; print substr($0,2)}' ~/passwords.txt)

	echo "Select sitename to copy username:"
	for ((i=0; i<${#array[@]}; i++)); do
	    echo "$(($i+1))) ${array[i]}"
	done
	read siteselect
	
        objectInfo=$(grep -A3 "^id: $(($siteselect-1))" ~/passwords.txt)
        objectInfoLineNumber=$(awk -v select="id: $(($siteselect-1))" '$0~select{print NR}' ~/passwords.txt)
        previousSite=$(echo "$objectInfo" | awk '/^site: / {$1=""; print substr($0,2)}')
        previousUser=$(echo "$objectInfo" | awk '/^user: / {$1=""; print substr($0,2)}')
        previousPass=$(echo "$objectInfo" | awk '/^pass: / {$1=""; print substr($0,2)}')

        select interactoption in "copy info" "list metadata" "edit" "delete" "exit"
	do 
	    case $interactoption in

	    "copy info")
	    # Selects the site to copy and copies the username to clipboard 
	    # (pbcopy only works on mac)
            echo "$previousUser" | pbcopy

	    echo "Username copied!"
	    echo "Press enter when you would like to copy the password..."
	    read

	    # Copies the password to clipboard	
            echo "$previousPass" | pbcopy
	    echo "Password copied!"
	    ;;

	    "list metadata")
	    ;;

	    edit)
                echo "Site Name ($previousSite):"
	        read sname
                echo "Username ($previousUser):"
	        read uname
                echo "Password: ($previousPass)"	
	        read -s pass

                if [[ -n $sname ]]; then
                    sed -i '' "$(($objectInfoLineNumber+1))s/$previousSite/$sname/g" ~/passwords.txt
                fi
                
                if [[ -n $uname ]]; then
                    sed -i '' "$(($objectInfoLineNumber+2))s/$previousUser/$uname/g" ~/passwords.txt
                fi

                if [[ -n $pass ]]; then
                    sed -i '' "$(($objectInfoLineNumber+3))s/$previousPass/$pass/g" ~/passwords.txt
                fi

                echo 
                echo "Account successfully updated!"
	    ;;

	    delete)
                sed -i '' $(($objectInfoLineNumber)),$(($objectInfoLineNumber+5))d ~/passwords.txt
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
	echo "id: $(($id + 1))" >> ~/passwords.txt 
	echo "site: $sname" >> ~/passwords.txt
	echo "user: $uname" >> ~/passwords.txt
	echo "pass: $pass" >> ~/passwords.txt
	echo " " >> ~/passwords.txt
	;;

	exit) 
        exit 0
        ;; 
		
	*) echo "Other"
        ;;
	esac
done

#fi
