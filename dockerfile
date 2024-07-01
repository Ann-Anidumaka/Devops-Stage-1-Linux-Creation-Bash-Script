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

# Run the script
CMD ["bash", "/usr/local/bin/create_users.sh", "/usr/local/bin/users.txt"]