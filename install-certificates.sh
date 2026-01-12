#!/bin/bash
set -e

# Pick these from CI
#ACCESS_TOKEN=
#CERTIFICATES_URL=
#CERTIFICATES_PASSPHRASE=
#RUNNER_TEMP=

certs_url="${CERTIFICATES_URL/https:\/\//https://${ACCESS_TOKEN}@}"
certs_passphrase=$CERTIFICATES_PASSPHRASE
certs_filename=certificates.zip
tmp_root=$RUNNER_TEMP/certificates

p12_path="$tmp_root/certificates.p12"
p12_password=""
keychain_path="$tmp_root/tmp.keychain-db"
keychain_password=""
keychain_timeout=$((30 * 60)) # 30 minutes
profiles_root=~/Library/Developer/Xcode/UserData/Provisioning\ Profiles/

# ZIP
rm -rf "$tmp_root"
mkdir -p "$tmp_root"
curl -O "$certs_url"
unzip -P "$certs_passphrase" -d "$tmp_root" `basename $certs_url`

# Certificates
security create-keychain -p "$keychain_password" "$keychain_path"
security set-keychain-settings -lut $keychain_timeout
security unlock-keychain -p "$keychain_password" "$keychain_path"
security import "$p12_path" -P "$p12_password" -A -t cert -f pkcs12 -k "$keychain_path"
security set-key-partition-list -S apple-tool:,apple: -k "$keychain_password" "$keychain_path"
security list-keychain -d user -s "$keychain_path"

# Provisioning
mkdir -p "$profiles_root"
cp "$tmp_root"/*.mobileprovision "$tmp_root"/*.provisionprofile "$profiles_root"
