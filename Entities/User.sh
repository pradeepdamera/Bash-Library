#!/bin/bash

# Anthony Rutledge
# aerutledge101@gmail.com
#
# https://www.linkedin.com/in/anthony-rutledge-2988b0125/
# https://stackoverflow.com/users/2495645/anthony-rutledge
#
# A Linux service library.
#
# 1) Makes managing users easier.
# 
# Note: Consider making a Group entity.
# ##########################################################
############################################################

function getUser ()
{
    declare -r USER=$1
    declare -r PASSWORD_FILE="/etc/passwd"

    getLine $USER $PASSWORD_FILE
    return $?
}

function isUser ()
{
    declare -r USER=$1
    declare -r PASSWORD_FILE="/etc/passwd"

    fileHas "^${USER}" $PASSWORD_FILE
    return $?
}

function setPassMaxDays ()
{
    declare -r DAYS=$1

    declare -r TARGET_PATTERN="^PASS_MAX_DAYS\t[0-9]+?"
    declare -r SUBSTITUTION="PASS_MAX_DAYS\t${DAYS}"
    declare -r INPUT_FILE=/etc/login.defs

    if isConfigurable $INPUT_FILE
    then 
        updateRecord $(getLineNumber $TARGET_PATTERN $INPUT_FILE) $TARGET_PATTERN $SUBSTITUTION $INPUT_FILE
        return $?
    fi
    
    errorMessage "Error: Unable to set PASS_MAX_DAYS to ${DAYS} in ${INPUT_FILE}. Check permissions."
    return 2
}

function setPassWarnAge ()
{
    declare -r DAYS=$1

    declare -r TARGET_PATTERN="^PASS_WARN_AGE\t[0-9]+?"
    declare -r SUBSTITUTION="PASS_WARN_AGE\t${DAYS}"
    declare -r INPUT_FILE=/etc/login.defs

    if isConfigurable $INPUT_FILE
    then 
        message "Setting PASS_WARN_AGE to ${DAYS}."
        updateRecord $(getLineNumber $TARGET_PATTERN $INPUT_FILE) $TARGET_PATTERN $SUBSTITUTION $INPUT_FILE
        return $?
    fi
    
    errorMessage "Error: Unable to set PASS_WARN_AGE to ${DAYS} in ${INPUT_FILE}. Check permissions."
    return 2
}

function setPasswordDefaults ()
{
    declare -r PASS_MAX_DAYS=$1
    declare -r PASS_WARN_AGE=$2

    message "Setting PASS_MAX_DAYS to ${PASS_MAX_DAYS}."

    if setPassMaxDays $PASS_MAX_DAYS # 90 
    then
        message "PASS_MAX_DAYS set to ${PASS_MAX_DAYS} days."
    else
        errorMessage "Error: Unable to set PASS_MAX_DAYS to ${PASS_MAX_DAYS} in. Check permissions in /etc/login.defs"
    fi

    if setPassWarnAge $PASS_WARN_AGE # 10
    then
        message "PASS_WARN_AGE set to ${PASS_WARN_AGE} days."
    else
        errorMessage "Error: Unable to set PASS_WARN_AGE to ${PASS_WARN_AGE} in. Check permissions in /etc/login.defs"
    fi
}

function showChangePasswordReport ()
{
    if (( $1 == 0 ))
    then 
        message "Password changed successfully!"
    else
        errorMessage "Failed to change password!"
    fi
}

function setPassword ()
{
    declare -r USER=$1

    message "Setting password for $USER ..."
    passwd $USER
    showChangePasswordReport $?
}

function setManyPasswords ()
{
    message "Setting passwords for $*"

    for user in "$@"
    do
        setPassword $user
        newline
    done
}

function configureHomeDir()
{
    declare -r USER=$1

    chown ${USER}:${USER} /home/${USER}
    chmod 700 /home/${USER}
}

function secureHomeDirs ()
{
    message "Securing home directories for: $*"

    for user in "$@"
    do
        configureHomeDir $user
        newline
    done
}

function secureHomeDirsFromFile ()
{
    message "Securing home directories from this file: ${1}"

    declare -r USER_ACCOUNTS_FILE=$1
    declare usersString=$(fileToString $USER_ACCOUNTS_FILE)

    read -a users <<< $usersString
    secureHomeDirs "${users[@]}"
}

function showUseraddReport ()
{
    typset -ir USER_ADD_RESULT=$1
    declare -r USER=$2

    if (( $USER_ADD_RESULT == 0 ))
    then 
        message "Success: $USER user added."
        return 0
    else
        errorMessage "Failure: $USER not added.}"
    fi
    
    return 1
}

function addRegularUser ()
{
    declare -r USER=$1

    if [[ ! isUser $USER ]]
    then
        useradd -d /home/${USER} -e 2021-01-01 -c "Normal user." -s /bin/sh -U $USER
        showUseraddReport $? $USER
        return $?
    fi

    errorMessage "The $USER user already exist! No user added."
    return 1
}

function addAccounts ()
{
    for user in "$@"
    do
        addRegularUser $(echo $user | trim)
    done
}

function addAccountsFromFile ()
{
    declare -r USER_ACCOUNTS_FILE=$1
    declare usersString=$(fileToString $USER_ACCOUNTS_FILE)
    
    read -a users <<< $usersString
    addAccounts "${users[@]}"
}
