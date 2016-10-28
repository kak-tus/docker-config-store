#!/usr/bin/env sh

# Consul

list=$( printenv | fgrep CONF_CONSUL_ | awk -F '=' '{ print $1 }' )

if [ -n "$list" ]; then
  CONSUL_CLI="consul-cli --consul $CONSUL_HTTP_ADDR --token $CONSUL_TOKEN"
  $CONSUL_CLI status leader >/dev/null 2>&1

  if [ $? = 1 ]; then
    echo 'Consul unacessible'
    exit 1
  fi

  for var in $list; do
    val=$( printenv | fgrep $var | awk -F '=' '{ print $2 }' )
    echo "Process consul $val"

    key=$( echo $val | awk -F ';' '{ print $1 }' )
    key_val=$( echo $val | awk -F ';' '{ print $2 }' )

    exists=$( $CONSUL_CLI kv read $key 2>/dev/null )
    if [ -z "$exists" ]; then
      echo 'Store value'
      $CONSUL_CLI kv write $key $key_val

      if [ $? = 1 ]; then
        echo 'Consul error'
        exit 1
      fi

      echo 'Value stored'
    else
      echo 'Value exists'
    fi
  done
fi

# Consul ACL

list=$( printenv | fgrep CONF_CONSULACL_ | awk -F '=' '{ print $1 }' )

if [ -n "$list" ]; then
  CONSUL_CLI="consul-cli --consul $CONSUL_HTTP_ADDR --token $CONSUL_TOKEN"
  $CONSUL_CLI status leader >/dev/null 2>&1

  if [ $? = 1 ]; then
    echo 'Consul unacessible'
    exit 1
  fi

  for var in $list; do
    val=$( printenv | fgrep $var | awk -F '=' '{ print $2 }' )
    echo "Process consul ACL $val"

    token=$( echo $val | awk -F ';' '{ print $1 }' )
    name=$( echo $val | awk -F ';' '{ print $2 }' )
    type=$( echo $val | awk -F ';' '{ print $3 }' )

    if [ $type == 'management' ]; then
      type="--management"
    else
      type=""
    fi

    echo 'Create or update ACL'

    $CONSUL_CLI acl update $token --name $name $type

    if [ $? = 1 ]; then
      echo 'Consul error'
      exit 1
    fi

    echo 'ACL created or updated'
  done
fi

# Vault

list=$( printenv | fgrep CONF_VAULT_ | awk -F '=' '{ print $1 }' )

if [ -n "$list" ]; then
  vault status >/dev/null 2>&1

  if [ $? = 1 ]; then
    echo 'Vault unacessible'
    exit 1
  fi

  for var in $list; do
    val=$( printenv | fgrep $var | awk -F '=' '{ print $2 }' )
    echo "Process vault $val"

    key=$( echo $val | awk -F ';' '{ print $1 }' )
    pass=$( echo $val | awk -F ';' '{ print $2 }' )

    exists=$(vault read -field=value $key 2>/dev/null)
    if [ -z "$exists" ]; then
      echo 'Store value'
      echo -n "$pass" | vault write $key value=- ttl=86400

      if [ $? = 1 ]; then
        echo 'Vault error'
        exit 1
      fi

      echo 'Value stored'
    else
      echo 'Value exists'
    fi
  done
fi

exit 0
