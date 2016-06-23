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

ldap_nslcdconfig () {
  LDAPPASS=$(getsecret ldap)
  echo "uid nslcd
gid nslcd

uri ldap://$PROJECT-ldap/

base $LDAPORG
scope subtree

binddn cn=admin,$LDAPORG
bindpw $LDAPPASS
rootpwmoddn cn=admin,$LDAPORG
rootpwmodpw $LDAPPASS

"
}

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

ldap_add() {
  local ldappass=$(getsecret ldap)
  printf "%s" "$1" | ldapadd -h $LDAPIP -p $LDAPPORT -D "cn=admin,$LDAPORG" -w "$ldappass"
}

ldap_nextuid() {

  local ldappass=$(getsecret ldap)

  local maxid=`ldapsearch -h $LDAPIP -p $LDAPPORT \
    -D "cn=admin,$LDAPORG" -w "$ldappass" \
    -b "ou=users,$LDAPORG" -s one \
    "objectclass=posixAccount" uidnumber | \
    grep uidNumber | awk '{ if ($1 != "#") print $2 }' | sort | tail -n 1`

  printf "%d" $((maxid + 1))
}

ldap_adduser() {
  local username=$1
  local firstname=$2
  local lastname=$3
  local email=$4
  local pass=$5
  local uid=$6
  
  echo "Adding LDAP user $firstname $lastname ($username)..."

  ldap_add "dn: uid=$username,ou=users,$LDAPORG
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
  docker $DOCKERARGS exec $PROJECT-gitlab /opt/gitlab/bin/gitlab-rails r "$1"
}

gitlab_adduser() {
  local username=$1
  local firstname=$2
  local lastname=$3
  local email=$4
  local pass=$5
  
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

gitlab_resetpass() {
  local username=$1
  local pass=$2
  
  # TODO: find a way to do via API
  
  gitlab_exec "
u = User.find_by_username(\"$username\")
u.password = \"$pass\"
u.save!
"
}

gitlab_makeadmin() {
  local username=$1
  
  # TODO: find a way to do via API
  
  gitlab_exec "
u = User.find_by_username(\"$username\")
u.admin = true
u.save!
"
}

gitlab_session() {
  local username=$1
  local pass=$2
  
  curl -X POST \
    "http://$GITLABIP/gitlab/api/v3/session?login=$username&password=$pass" | \
    grep -oEi '"private_token":"([^"])*"' | cut -d':' -f 2 | cut -d'"' -f 2
}

gitlab_addsshkey() {
  local username=$1
  local pass=$2
  
  local token=$(gitlab_session $username $pass)
  
  curl -X POST -G \
    -H "private-token: $token" \
    --data-urlencode key@$SRV/home/$username/.ssh/gitlab.key.pub \
    "http://$GITLABIP/gitlab/api/v3/user/keys?title=gitlabkey"
}

gitlab_addoauthclient() {
  local name=$1
  local uri=$2
  
  gitlab_exec "
a = Doorkeeper::Application.new
a.name = \"$name\"
a.redirect_uri = \"$uri\"
a.save!

print(a.uid, \" \", a.secret, \"\\n\")
"
}

getservices() {
  if [ $# -lt 2 ] || [ "$2" = "all" ]; then
    echo "ldap home gitlab notebook owncloud nginx"
  else
    local args=($@)
	echo "${args[@]:1}"
  fi
}

reverse() {
  echo "$@" | awk '{ for (i=NF; i>1; i--) printf("%s ",$i); print $1; }'
}

createsecret() {
  local name=$1
  #openssl rand -base64 32 > $SECRETS/$name.secret
  echo "$DUMMYPASS" > $SECRETS/$name.secret
  cat $SECRETS/$name.secret
}

getsecret() {
  local name=$1
  cat $SECRETS/$name.secret
}

cpetc() {
  printf "$(ldap_nslcdconfig)\n\n" > ../../etc/nslcd.conf
  mkdir etc
  cp -R ../../etc/* etc/
}

rmetc() {
  rm -R etc
}

adduser() {

    # TODO: replace this with python script

  local username=$1
  local firstname=$2
  local lastname=$3
  local email=$4
  local pass=$5
  local uid=$6
  
  if [ -z $uid ]; then
    uid=$(ldap_nextuid)
  fi
  
  echo "Adding new user $username with uid $uid..."
  
  ldap_adduser "$username" "$firstname" "$lastname" "$email" "$pass" "$uid"
  gitlab_adduser "$username" "$firstname" "$lastname" "$email" "$pass"
  
  # Create home directory
  mkdir -p $SRV/home/$username
  
  # Create jupyter config
  mkdir -p $SRV/home/$username/.jupyter
  cp $KOOPLEXWD/modules/notebook/jupyter_notebook_config.py $SRV/home/$username/.jupyter/
  
  # Generate git private key
  SSHKEYPASS=$(getsecret sshkey)
  mkdir -p $SRV/home/$username/.ssh
  rm $SRV/home/$username/.ssh/gitlab.key
  ssh-keygen -N "$SSHKEYPASS" -f $SRV/home/$username/.ssh/gitlab.key

  # Register key in Gitlab
  gitlab_addsshkey $username $pass
  
  # Set home owner
  chown -R $uid:$uid $SRV/home/$username
  # TODO set permissions
  
  echo "New user created: $uid $username"
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

isindocker() {
  local d=`cat /proc/1/cgroup | grep -e "systemd:/.+"`
  
  if [ -z "$d" ]; then
    echo 0
  else
    echo 1
  fi
}

config() {
  source config.sh
  
  KOOPLEXWD=`pwd`
  
  SRV=$ROOT/$PROJECT/srv 
  SRC=$ROOT/$PROJECT/src
  SECRETS=$SRV/.secrets

  ADMINIP=$(ip_addip "$SUBNET" 2)
  
  LDAPIP=$(ip_addip "$SUBNET" 3)
  LDAPORG=$(ldap_fdqn2cn "$DOMAIN")
  LDAPSERV=$PROJECT-ldap
  LDAPPORT=389

  HOMEIP=$(ip_addip "$SUBNET" 4)
  
  GITLABIP=$(ip_addip "$SUBNET" 5)
  
  JUPYTERHUBIP=$(ip_addip "$SUBNET" 6)
  
  OWNCLOUDIP=$(ip_addip "$SUBNET" 7)
  
  NOTEBOOKIP=$(ip_addip "$SUBNET" 8)
  
  PROXYIP=$(ip_addip "$SUBNET" 9)
  
  NGINXIP=$(ip_addip "$SUBNET" 16)
  
  if [ $(isindocker) -eq 1 ]; then
    echo "Process is running inside a docker container."
  else
    echo "Process is running on the host."
  fi
}

config