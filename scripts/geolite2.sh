#!/bin/sh
set -e

# Check if the MAXMIND_LICENSE_KEY environment variable is defined.
if [ -z "$MAXMIND_LICENSE_KEY" ]; then
  echo "Error: MAXMIND_LICENSE_KEY is not defined."
  exit 1
fi

# Set the edition ID, defaulting to GeoLite2-City if not provided.
EDITION_ID="${EDITION_ID:-GeoLite2-City}"

# Construct the URL for downloading the GeoLite2 database using the provided license key.
URL="https://download.maxmind.com/app/geoip_download?edition_id=${EDITION_ID}&license_key=${MAXMIND_LICENSE_KEY}&suffix=tar.gz"

# Download the database file.
wget -qO /tmp/geo.tar.gz "$URL"

# If MAXMIND_SHA256 is specified, verify the integrity of the downloaded file.
if [ -n "$MAXMIND_SHA256" ]; then
  echo "$MAXMIND_SHA256  /tmp/geo.tar.gz" | sha256sum -c -
fi

# Extract the archive to /tmp without preserving the top-level directory.
tar -xzf /tmp/geo.tar.gz --strip-components=1 -C /tmp/
if [ ! -f "/tmp/${EDITION_ID}.mmdb" ]; then
  echo "Error: /tmp/${EDITION_ID}.mmdb not found."
  exit 1
fi
mv "/tmp/${EDITION_ID}.mmdb" /etc/nginx/${EDITION_ID}.mmdb

# Remove the temporary archive file.
rm /tmp/geo.tar.gz
echo "GeoLite2 updated successfully."
