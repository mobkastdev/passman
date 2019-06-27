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
	
			select interactoption in "copy info" "list metadata" "edit" "delete" "exit"
			do 
				case $interactoption in

					"copy info")
					# Selects the site to copy and copies the username to clipboard 
					# (pbcopy only works on mac)
					grep -A2 "id: $(($siteselect-1))" ~/passwords.txt | awk '/^user: / {$1=""; print substr($0,2)}'| pbcopy

					echo "Username copied!"
					echo "Press enter when you would like to copy the password..."
					read

					# Copies the password to clipboard	
					grep -A3 "id: $(($siteselect-1))" ~/passwords.txt | awk '/^pass: / {$1=""; print substr($0,2)}'| pbcopy
					echo "Password copied!"
					;;

					"list metadata")
					;;

					edit)
					;;

					delete)
					;;
					
					exit)
					break
					;;
				esac
			done

			array=()
			;;

		add)
			echo $id
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

		exit) exit 0;; 
		
		*) echo "Other";;
	esac
done

#fi
