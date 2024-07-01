# Devops-Stage-1-Linux-Creation-Bash-Script

# Project Overview
Automated User Creation with Docker
This project demonstrates a Dockerized Bash script for streamlined user creation.

## Key Features

- Efficient User Creation: Automates user provisioning, this enhances efficiency and reduces administrative overhead.
- Consistent User Setup: Ensures a strict adherance to the use of standardized user environments across deployments, promoting consistency.
- Security Measures: These measures include generation of strong, random passwords and the implementation of secure password storage mechanisms.
- Detailed Audit Logs: Maintains comprehensive logs of all user creation actions, for better audits.

## Deployment instructions

### Step 1: Create the txt file containing the users and their groups
- ```bash
   light;sudo,dev,www-data
   ann;sudo
   kosi;dev,www-data
   evie;finance,hr
   dolapo;marketing,sales
   ify;it,security,network

   
### Step 2: Create a Dockerfile:
**For increased consistency and effortless deployment, containerize the user creation script using a Dockerfile**
 - ```bash
   # Use an official Alpine as a base image
   FROM alpine:latest

   # Install necessary packages
   RUN apk update && apk add --no-cache \
    sudo \
    openssl \
    bash \
    shadow \
    util-linux \
    vim

   # Copy the script and users.txt into the container
   COPY create_users.sh /usr/local/bin/create_users.sh
   COPY users.txt /usr/local/bin/users.txt

   # Make the script executable
   RUN chmod +x /usr/local/bin/create_users.sh

   # Specify script to run on container start
   CMD ["bash", "/usr/local/bin/create_users.sh", "/usr/local/bin/users.txt"]


### Step 3: Create the Script (create_users.sh)
**automates the process of creating users, assigning them to appropriate groups (e.g., sudo), setting home directory permissions, and logging all actions to a file for auditing purposes**
- ```bash
  #!/bin/bash

  # Check if the script is run as root (superuser)
  if [ "$(id -u)" -ne 0 ]; then
    echo "Please run this script as root or using sudo."
    exit 1
  fi

  # Check if the input file is provided
  if [ -z "$1" ]; then
    echo "Usage: $0 <name-of-text-file>"
    exit 1
  fi

  INPUT_FILE="$1"
  LOG_FILE="/var/log/user_management.log"
  PASSWORD_FILE="/var/secure/user_passwords.csv"

  # Create log and password files if they do not exist
  touch $LOG_FILE
  mkdir -p /var/secure
  touch $PASSWORD_FILE
  chmod 600 $PASSWORD_FILE

  # Function to generate random passwords
  generate_password() {
    openssl rand -base64 12
  }

  # Read the input file line by line
  while IFS=';' read -r username groups; do
    username=$(echo "$username" | xargs)
    groups=$(echo "$groups" | xargs)

    # Check if user already exists
    if id "$username" &>/dev/null; then
        echo "User $username already exists, skipping..." | tee -a $LOG_FILE
        continue
    fi

    # Create a personal group for the user
    addgroup "$username"

    # Create the user with the personal group and home directory
    adduser -D -G "$username" -s /bin/bash "$username"

    # Add the user to additional groups if specified
    if [ -n "$groups" ]; then
        IFS=',' read -r -a group_array <<< "$groups"
        for group in "${group_array[@]}"; do
            group=$(echo "$group" | xargs)
            if ! getent group "$group" > /dev/null; then
                addgroup "$group"
            fi
            adduser "$username" "$group"
        done
    fi

    # Generate a random password for the user
    password=$(generate_password)

    # Set the user's password
    echo "$username:$password" | chpasswd

    # Log the actions
    echo "Created user $username with groups $groups and home directory" | tee -a $LOG_FILE

    # Store the username and password securely
    echo "$username,$password" >> $PASSWORD_FILE
    done < "$INPUT_FILE"

    echo "User creation process completed. Check $LOG_FILE for details."
  

### Step 4: Build the Docker Image and Run the Docker Container:
 - ```bash
   docker build -t user_creation .
   docker run --rm -it --name user_creation_container user_creation

### Step 5: Copy Logs from Docker container to local machine
   
 - ```bash
   docker run -it --name user_creation_container user_creation
