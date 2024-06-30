#!/bin/bash

# Constants
LOGFILE="/var/log/user_management.log"
PASSFILE="/var/secure/user_passwords.csv"
INPUTFILE="$1"

# Ensure secure storage for passwords
mkdir -p /var/secure
chmod 700 /var/secure

# Initialize log file
echo "User management actions log" > "$LOGFILE"

# Function to generate a random password
generate_password() {
    openssl rand -base64 12
}

# Read input file line by line and process each user
while IFS=';' read -r username groups || [[ -n "$username" ]]; do
    # Skip empty lines or lines with only whitespace
    if [[ -z "${username// }" ]]; then
        continue
    fi

    # Check if user already exists
    if id "$username" &>/dev/null; then
        echo "User $username already exists" | tee -a "$LOGFILE"
    else
        # Create user
        useradd -m -s /bin/bash "$username"
        echo "Created user $username" | tee -a "$LOGFILE"

        # Generate password
        password=$(generate_password)

        # Set password
        echo "$username:$password" | chpasswd
        echo "$username,$password" >> "$PASSFILE"
    fi

    # Process groups
     IFS=',' read -ra group_arr <<< "$groups"
    for group in "${group_arr[@]}"; do
        if [ -n "$group" ]; then
            if ! getent group "$group" &>/dev/null; then
                groupadd "$group"
                echo "Created group $group"
            fi
            usermod -aG "$group" "$username"
            echo "Added user $username to group $group"
        fi
    done

    # Set permissions for the home directory
    chown -R "$username:$username" "/home/$username"
    chmod 700 "/home/$username"
    echo "Set permissions for home directory of $username" | tee -a "$LOGFILE"

done < "$INPUTFILE"

echo "User creation script completed." | tee -a "$LOGFILE"