#!/bin/sh
# ------------------------------------------------------------------------------------------------
# Entry Point Script for Nginx Container
#
# This script performs the following actions:
# 1. Dynamically substitutes environment variables in the Nginx configuration files.
# 2. Sets up a cron job to periodically update the GeoLite2 database.
# 3. Starts the cron daemon in the background.
# 4. Executes the command passed as arguments.
#
# Ensure that the necessary cron configuration file and permissions are correctly set.
# ------------------------------------------------------------------------------------------------

# Dynamically substitute environment variables in configuration files
for file in /etc/nginx/nginx.conf /etc/nginx/conf.d/*.conf; do
  [ -f "$file" ] && envsubst < "$file" > "${file}.tmp" && mv "${file}.tmp" "$file"
done

# Install the cron job for periodic GeoLite2 database updates
crontab /usr/local/bin/geolite2.cron

# Start the cron daemon in the background
crond

# Execute the command passed as arguments
exec "$@"
