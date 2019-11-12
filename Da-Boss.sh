#!/bin/bash
#
###############################################################################################################################################
#
# ABOUT THIS PROGRAM
#
#   This Script is designed for use in JAMF
#
#   This script was designed to check the Accounts that have local Admin permissions and reset the list if required
#
###############################################################################################################################################
#
# HISTORY
#
#   Version: 1.1 - 12/11/2019
#
#   - 01/03/2018 - V1.0 - Created by Headbolt
#
#   - 12/11/2019 - V1.1 - Updated by Headbolt
#							In Depth checking of Users assigned by AD Binding
#                           More comprehensive error checking and notation
#
###############################################################################################################################################
#
#   DEFINE VARIABLES & READ IN PARAMETERS
#
###############################################################################################################################################
#
# Grabs the list of the required Local Admins (MUST se seperated by comma's) from JAMF variable #4 eg. Admin,Support
AdminUsers=$4
# Grabs the NETBIOS name of the AD Domain that the users Machine Resides in from JAMF variable #5 eg. DOMAIN
DOMAIN=$5
# Grabs the Username of a user that has been granted specific permissions just for this task from JAMF variable #6 eg. username
# Recommended is Read permissions ONLY to the relevant area#s of AD 
USER=$6
# Grabs the Password of a user that has been granted specific permissions just for this task from JAMF variable #7 eg. password
PASS=$7
#
# Set the name of the script for later logging
ScriptName="append prefix here as needed -  - Local Admins"
#
# Set any Default "Override" AdminAccount that must always remain
DefaultAdmin="administrator"
# Grab the Current Local Admins List before any processing is done
CurrentLocalADAdmins=$(dsconfigad -show | grep "Allowed admin groups" | cut -c 36-)
#
###############################################################################################################################################
#
# Defining Functions
#
###############################################################################################################################################
#
# AD Creds Check Function
#
ADchecks(){
#
/bin/echo Checking AD Creds Are Present
#
ADcredsChecks=""
#
if [[ $DOMAIN != "" ]] 
	then
		ADcredsChecks="OK"
		if [[ $USER != "" ]] 
			then
				ADcredsChecks="OK"
				if [[ $PASS != "" ]] 
					then
						ADcredsChecks="OK"
					else
						ADcredsChecks="MISSING"
				fi
			else
				ADcredsChecks="MISSING"
		fi     
	else
		ADcredsChecks="MISSING"
fi
#
if [[ $ADcredsChecks == "OK" ]] 
	then
		/bin/echo AD Creds Are Present
	else
		/bin/echo AD Creds Missing, Skipping AD Related Sections
fi
#
}
#
###############################################################################################################################################
#
# Current Admin Check Function
#
AdminCheck(){
#
AdminArray=""
#
for username in $(dscl . list /Users UniqueID | awk '$2 > 300 { print $1 }' | tr "[A-Z]" "[a-z]")
	do
		if [[ $(dsmemberutil checkmembership -U "${username}" -G admin) == *not* ]] 
			then
                AdminArray=$AdminArray
			else
				AdminArray+=$username
				AdminArray+=" "
		fi
	done
#
}
#
###############################################################################################################################################
#
# Add User Function
#
AddUsers(){
#
/bin/echo Processing any required additions
#
IFS=';' # Internal Field Seperator Delimiter is set to SemiColon (;)
read -ra AddUser <<< "$AddArray" # Read in the Array of Users to Process for Addition
for PlusUser in "${AddUser[@]}" # Process Each User in the "Add" Array
	do # access each element of array
		# Ouput which user we are adding. For Reporting Purposes
		/bin/echo Adding $PlusUser to Admins List
		# Add User to the 3 relevant Groups.
		dseditgroup -o edit -a $PlusUser admin
		dseditgroup -o edit -a $PlusUser _appserveradm
		dseditgroup -o edit -a $PlusUser _appserverusr
	done
#
}
#
#
###############################################################################################################################################
#
# Remove User Function
#
RemoveUsers(){
#
/bin/echo Processing any required removals
#
IFS=';' # Internal Field Seperator Delimiter is set to SemiColon (;)
read -ra RemoveUser <<< "$RemoveArray" # Read in the Array of Users to Process for Removal
for REMuser in "${RemoveUser[@]}" # Process Each User in the "Remove" Array
	do # access each element of array
		read -ra KeepUser <<< "$KeepArray" # Read in the Array of Users to Process to Keep
		for noDELuser in "${KeepUser[@]}" # Process Each User in the "Keep" Array
			do # access each element of array
				if [[ $noDELuser != $REMuser ]] # Compare Remove and Keep Array Users for Matches
					then
						if [[ $REM == "NO" ]]
							then
								REM=$REM
							else
								REM="YES"
						fi
					else 
						REM="NO"
				fi
			done  
		if [[ $REM == "YES" ]] # Check the Output of the above Checking Logic, and process the User
			then
				# Ouput which user we are removing. For Reporting Purposes
				/bin/echo Removing $REMuser from Admins List
				# Remove User from the 3 relevant Groups.
				dseditgroup -o edit -d $REMuser admin
				dseditgroup -o edit -d $REMuser _appserveradm
				dseditgroup -o edit -d $REMuser _appserverusr
#			else
				# This User is to be Kept, Output that. For Reporting Purposes
#				/bin/echo User $REMuser is in a Valid Group keeping as an Admin
		fi
	done
#
}
#
###############################################################################################################################################
#
# Section End Function
#
SectionEnd(){
#
# Outputting a Blank Line for Reporting Purposes
/bin/echo
#
# Outputting a Dotted Line for Reporting Purposes
/bin/echo  -----------------------------------------------
#
# Outputting a Blank Line for Reporting Purposes
/bin/echo
#
}
#
###############################################################################################################################################
#
# Script End Function
#
ScriptEnd(){
#
/bin/echo Ending Script '"'$ScriptName'"'
#
# Outputting a Blank Line for Reporting Purposes
/bin/echo
#
# Outputting a Dotted Line for Reporting Purposes
/bin/echo  -----------------------------------------------
#
# Outputting a Blank Line for Reporting Purposes
/bin/echo
#
}
#
###############################################################################################################################################
#
# End Of Function Definition
#
###############################################################################################################################################
# 
# Begin Processing
#
####################################################################################################
#
# Outputs a blank line for reporting purposes
/bin/echo
SectionEnd
#
AdminCheck
#
/bin/echo Current Admins list = $AdminArray
# Outputs a blank line for reporting purposes
/bin/echo
/bin/echo CurrentLocalADAdmins = $CurrentLocalADAdmins
SectionEnd
#
ADchecks
SectionEnd
/bin/echo Checking Admin Users
SectionEnd
#
# generate user list of users with UID greater than 200.
# Check to see which usernames are reported as being admins.
# The check is running dsmemberutil's check membership
# and listing the accounts that are being reported as admin users.
# Actual check is for accounts that are NOT not an admin (i.e. not standard users.)
#
for username in $(dscl . list /Users UniqueID | awk '$2 > 200 { print $1 }' | tr “[A-Z]” “[a-z]”)
	do # access each element of array
		unset IFS # Internal Field Seperator Delimiter disabled
		# Grab AD CN for the User if Present
        
       if [[ $ADcredsChecks == "OK" ]] 
then        
        
		ADcnString=$(dscl "/Active Directory/$DOMAIN/All Domains" -read /Users/$username dsAttrTypeNative:cn 2>/dev/null)
		ADcn=$(/bin/echo $ADcnString | cut -c 22-) # Strip out String to Just Get Display Name
        
        else 
        ADcnString=""
        ADcn=""
        
        fi
        
		if [[ $(dsmemberutil checkmembership -U "${username}" -G admin) != *not* ]] # Check if User is an Admin
			then
				# Any reported accounts are added to the array list
				if [[ $AdminUsers != *$username* ]]
					then
						/bin/echo Checking $username
						if [[ $username == $DefaultAdmin ]]
							then
								/bin/echo Keeping $username as it is 
								/bin/echo selected as a Default Admin
								SectionEnd
							else
								IFS=',' # Internal Field Seperator Delimiter is set to Comma (,)
								read -ra ADadmins <<< "$CurrentLocalADAdmins" # Read in the Array of Current Admin Users
								for i in "${ADadmins[@]}"
									do # access each element of array
										if [[ $ADcn != "" ]]
											then
												# Grab all AD Groups the User is in
												ADgroupString=$(dscl -u $USER -P $PASS "/Active Directory/$DOMAIN/All Domains" -read /Groups/${i} member)
												usr=$(echo $ADgroupString | grep "$ADcn OU=") # Grab the Users AD cn
											else
												usr=""
										fi
										#
										if [[ $usr != "" ]] # Check if User cn is in the Group
											then
												/bin/echo User '"'$username'"' is in Group '"'$i'"' # User is in the group
												KEEP=$(/bin/echo $KeepArray | grep $username) # Check if the User is in the Array of users to Keep
													if [[ $KEEP == "" ]]
														then # User is not in the Keep Array, add them with a delimiter after
															KeepArray+=$username
															KeepArray+=";"
													fi
										fi       
										REM=$(/bin/echo $RemoveArray | grep $username) # Check if User is in the Array to be removed
										if [[ $REM == "" ]]
											then # User is not in the Remove Array, add them with a delimiter after
												RemoveArray+=$username
												RemoveArray+=";"
										fi
									done
								KEEPend=$(/bin/echo $KeepArray | grep $username) # Checking the KeepEnd array for the user account
								if [[ $KEEPend != "" ]]
									then # User is in the array, output relevant message
										/bin/echo Marking $username to be kept as an Admin
								fi
								SectionEnd
						fi
				fi
		else # User is not an admin but should be
				if [[ $AdminUsers == *$username* ]] # Checking user against list and add to "Add" Array
					then
						/bin/echo Checking $username
						/bin/echo User '"'$username'"' is in list of Desired Local Admins
						/bin/echo Marking $username to be set as an Admin
						ADD=$(/bin/echo $AddArray | grep $username)
						if [[ $ADD == "" ]]
							then
								AddArray+=$username  
								AddArray+=";"
						fi
						SectionEnd     
				fi
		fi
	done
RemoveUsers
SectionEnd   
#
AddUsers
SectionEnd   
#
unset IFS
AdminCheck
/bin/echo New Admins list = $AdminArray
#
SectionEnd
ScriptEnd
