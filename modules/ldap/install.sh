#! /bin/sh

echo "Installing slapd $PROJECT-ldap [$LDAPIP]"

# Initialize LDAP directory with necessary schemas and items

mkdir -p $SRV/ldap/etc/
mkdir -p $SRV/ldap/var/

# Generate LDAP random password
LDAPPASS=$(createsecret ldap)

# Creating LDAP config file
echo "$(ldap_getconfig)" > ../../etc/nslcd.conf

# Install and execute docker image

docker $DOCKERARGS run -d \
  --name $PROJECT-ldap \
  --hostname $PROJECT-ldap \
  --net $PROJECT-net \
  --ip $LDAPIP \
  -p 666:$LDAPPORT \
  -v $SRV/ldap/etc:/etc/ldap \
  -v $SRV/ldap/var:/var/lib/ldap \
  -e SLAPD_PASSWORD="$LDAPPASS" \
  -e SLAPD_CONFIG_PASSWORD="$LDAPPASS" \
  -e SLAPD_DOMAIN=$DOMAIN \
  dinkel/openldap
  
echo "Waiting for slapd to start"
  
sleep 3
