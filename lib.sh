#! /bin/sh

# IP address functions

ip_ip2dec () {
  local a b c d ip=$@
  IFS=. read -r a b c d <<< "$ip"
  printf '%d\n' "$((a * 256 ** 3 + b * 256 ** 2 + c * 256 + d))"
}

ip_dec2ip () {
  local ip dec=$@
  for e in {3..0}
  do
    ((octet = dec / (256 ** e) ))
    ((dec -= octet * 256 ** e))
    ip+=$delim$octet
    delim=.
  done
  printf '%s\n' "$ip"
}

ip_addip () {
  local cidr=$1
  local offset=$2
  local network=`echo "$cidr" | egrep '^[0-9\.]+' -o`
  local netmask=`echo "$cidr" | egrep '[0-9]+$' -o`

  A=`ip_ip2dec "$network"`
  B=$offset
  local ip=$((A + B))

  ip_dec2ip "$ip"
}

# LDAP functions

ldap_fdqn2cn () {
  local aa q fdqn=$@
  IFS=. read -ra aa <<< "$fdqn"
  q=0
  for i in "${aa[@]}"
  do
    if test $q -gt 0
    then
     printf ','
    fi
    printf 'dc=%s' "$i"
	q=$((q + 1))
  done
}

ldap_exec() {
  local ldappass=$(getsecret ldap)
  printf "%s" "$1" | ldapadd -h $LDAPIP -p $LDAPPORT -D "cn=admin,$LDAPORG" -w "$ldappass"
}

ldap_adduser() {
  local username=$1
  local firstname=$2
  local lastname=$3
  local email=$4
  local uid=$5
  local pass=$6
  
  echo "Adding LDAP user $firstname $lastname ($username)..."

  ldap_exec "dn: uid=$username,ou=users,$LDAPORG
objectClass: simpleSecurityObject
objectClass: organizationalPerson
objectClass: person
objectClass: top
objectClass: inetOrgPerson
objectClass: posixAccount
objectClass: shadowAccount
sn: $lastname
givenName: $firstname
cn: $username
displayName: $firstname $lastname
uidNumber: $uid
gidNumber: $uid
loginShell: /bin/bash
homeDirectory: /home/$username
mail: $email
userPassword: $pass
shadowExpire: -1
shadowFlag: 0
shadowWarning: 7
shadowMin: 8
shadowMax: 999999
shadowLastChange: 10877
"
}

ldap_addgroup() {

  local name=$1
  local uid=$2
  
  local ldappass=$(getsecret ldap)
  
  echo "Adding LDAP group $name"

  echo "dn: cn=$name,ou=groups,$LDAPORG
objectClass: top
objectClass: posixGroup
cn: $name
gidNumber: $uid
" | \
  ldapadd -h $LDAPIP -p $LDAPPORT -D "cn=admin,$LDAPORG" -w "$ldappass"
  
}

# Gitlab functions

gitlab_exec() {
  docker exec compare-gitlab /opt/gitlab/bin/gitlab-rails r "$1"
}

gitlab_resetpass() {
  local username=$1
  local pass=$2
  
  gitlab_exec "
u = User.find_by_username(\"$username\")
u.password = \"$pass\"
u.save!
"
}

gitlab_adduser() {
  local username=$1
  local firstname=$2
  local lastname=$3
  local email=$4
  local uid=$5
  local pass=$6
  
  echo "Adding Gitlab user $firstname $lastname ($username)..."
  
  gitlab_exec "
u = User.new
u.name = \"$firstname $lastname\"
u.username = \"$username\"
u.password = \"$pass\"
u.email = \"$email\"
u.confirmed_at = Time.now
u.confirmation_token = nil
u.save!

i = Identity.new
i.provider = \"ldapmain\"
i.extern_uid = \"uid=$username,ou=users,$LDAPORG\"
i.user = u
i.user_id = u.id
i.save!
"
}

configure() {
  source config.sh
  
  SRV=$ROOT/$PROJECT/srv
  SECRETS=$SRV/.secrets

  LDAPIP=$(ip_addip "$SUBNET" 2)
  LDAPORG=$(ldap_fdqn2cn "$DOMAIN")
  LDAPSERV=$PROJECT-ldap
  LDAPPORT=389

  HOMEIP=$(ip_addip "$SUBNET" 3)

  GITLABIP=$(ip_addip "$SUBNET" 4)

  NGINXIP=$(ip_addip "$SUBNET" 16)
}

createsecret() {
  local name=$1
  #openssl rand -base64 32 > $SECRETS/$name.secret
  echo "almafa137" > $SECRETS/$name.secret
  cat $SECRETS/$name.secret
}

getsecret() {
  local name=$1
  cat $SECRETS/$name.secret
}

adduser() {
  local username=$1
  local firstname=$2
  local lastname=$3
  local email=$4
  local uid=$5
  local pass=$6
  
  ldap_adduser "$username" "$firstname" "$lastname" "$email" "$uid" "$pass"
  gitlab_adduser "$username" "$firstname" "$lastname" "$email" "$uid" "$pass"
}

modifyuser() {
  # TODO: implement

  echo Not implemented >&2
  exit 2
}

deleteuser() {
  # TODO: implement

  echo Not implemented >&2
  exit 2
}

resetpass() {
  # TODO: implement

  echo Not implemented >&2
  exit 2
}

configure