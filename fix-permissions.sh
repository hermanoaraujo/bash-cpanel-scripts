#!/bin/bash
function main() {
  [ -d /home/.hd/var/log ] && mkdir -p /home/.hd/var/log/

  local HOMEDIR
  
  if [ -z "$1" ]; then
    read -p "Fix permissions for which cPanel Username? " user;
  else
    user="$1"
  fi
  
  HOMEDIR=$(grep "^${user}:" /etc/passwd | cut -d: -f6)
  
  if [ ! -f /var/cpanel/users/"$user" ]; then
    echo "Error: User file \"/var/cpanel/users/$user\" is missing. This is likely an invalid user."
    return 1
  fi
  
  # the 'nobody' user's homedir is /, prevent it from chpwning a server.
  if [[ "$user" =~ ^(nobody|system|root)$ ]]; then
    echo "Error: This script does not work with system users." >&2
    return 2
  fi
  
  # Prevent destroying a server
  if ![[ $HOMEDIR =~ ^/home[0-9]*/"${user}" ]]; then
    echo "Error: Could not run fix on \"$HOMEDIR\". This is either an invalid or insecure path to recursively change permissions on."
    return 3
  fi
  
  local logfile=/home/.hd/var/log/fixhome.${user}.$(date +"%Y-%m-%d_%H%M").log
  echo "Fixing permissions for $user [Log: ${logfile}]"
  fixHome | tee ${logfile}
  echo "Done fixing permissions for \"$user\". Changes have been logged to: \"${logfile}\""
}

function fixHome() {
  # Fix ownership
  echo "Setting ownership for user $user"

  chown -vR $user:$user $HOMEDIR
  chmod -v 711 $HOMEDIR
  chown -v $user:nobody $HOMEDIR/public_html
  [ -d $HOMEDIR/.htpasswds ] && chown -v $user:nobody $HOMEDIR/.htpasswds
  chown -v $user:mail $HOMEDIR/etc $HOMEDIR/etc/* $HOMEDIR/etc/*/shadow* $HOMEDIR/etc/*/passwd* $HOMEDIR/mail/*/*/maildirsize $HOMEDIR/etc/*/*pwcache $HOMEDIR/etc/*/*pwcache/*

  # Fix permissions
  echo "Setting permissions for user $user"

  find $HOMEDIR/public_html/ -type f -exec chmod -v 644 {} +
  find $HOMEDIR/public_html/ -type d -exec chmod -v 755 {} +

  find $HOMEDIR -type d -name cgi-bin -exec chmod -v 755 {} +
  find $HOMEDIR -type f \( -name "*.cgi" -o -name "*.pl" -o -name "*.py" -o -name "*.perl" \) -exec chmod -v 755 {} +

  while read pipefile; do
    grep -q '#!' "$pipefile" && chmod +x "$pipefile"
  done < <(find $HOMEDIR -type f -name "pipe.php")

  find $HOMEDIR/mail/ ! -user $user -exec chown -v $user:$user {} +
  /scripts/mailperm --verbose --skipserverperm --skipmxcheck $user
}

main "$@"