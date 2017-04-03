#!/usr/bin/env sh

CONSUL_CLI="consul-cli --consul $CONSUL_HTTP_ADDR"

if [ -n "$CONSUL_TOKEN" ]; then
  CONSUL_CLI="$CONSUL_CLI --token $CONSUL_TOKEN"
fi

store_consul() {
  key=$1
  key_val=$2

  echo "Process consul key $key"

  $CONSUL_CLI kv write $key $key_val

  if [ $? = 1 ]; then
    echo 'Consul error'
    exit 1
  fi

  echo "Stored consul key $key"
}

store_consul_acl() {
  token=$1
  name=$2

  if [ "$3" = 'management' ]; then
    type="--management"
  else
    type=""
  fi

  echo "Process consul ACL token name $name"

  $CONSUL_CLI acl update $token --name $name $type

  if [ $? = 1 ]; then
    echo 'Consul error'
    exit 1
  fi

  echo "consul ACL token name $name created or updated"
}

store_vault() {
  key=$1
  key_val=$2
  regex=$3

  echo "Process vault key $key"

  if [ -z "$key_val" ]; then
    key_val=$( /usr/local/bin/random_regex.pl "$regex" )
    echo "Generate password by regex $regex"
  fi

  exists=$(vault read -field=value $key 2>/dev/null)
  if [ -z "$exists" ]; then
    echo "Store vault key $key"
    echo -n "$key_val" | vault write $key value=- ttl=86400

    if [ $? = 1 ]; then
      echo 'Vault error'
      exit 1
    fi

    echo "Stored vault key $key"
  else
    echo "Vault key $key exists"
  fi
}

status_vault() {
  vault status >/dev/null 2>&1

  if [ $? = 1 ]; then
    echo 'Vault unacessible'
    exit 1
  fi
}

status_consul() {
  $CONSUL_CLI status leader >/dev/null 2>&1

  if [ $? = 1 ]; then
    echo 'Consul unacessible'
    exit 1
  fi
}

# Consul

list=$( printenv | fgrep CONF_CONSUL_ | awk -F '=' '{ print $1 }' )

if [ -n "$list" ]; then
  status_consul

  for var in $list; do
    val=$( printenv $var )

    key=$( echo $val | awk -F ';' '{ print $1 }' )
    key_val=$( echo $val | awk -F ';' '{ print $2 }' )

    store_consul "$key" "$key_val"
  done
fi

# Consul ACL

list=$( printenv | fgrep CONF_CONSULACL_ | awk -F '=' '{ print $1 }' )

if [ -n "$list" ]; then
  status_consul

  for var in $list; do
    val=$( printenv $var )

    token=$( echo $val | awk -F ';' '{ print $1 }' )
    name=$( echo $val | awk -F ';' '{ print $2 }' )
    type=$( echo $val | awk -F ';' '{ print $3 }' )

    store_consul_acl "$token" "$name" "$type"
  done
fi

# Vault

list=$( printenv | fgrep CONF_VAULT_ | awk -F '=' '{ print $1 }' )

if [ -n "$list" ]; then
  status_vault

  for var in $list; do
    val=$( printenv $var )

    key=$( echo $val | awk -F ';' '{ print $1 }' )
    pass=$( echo $val | awk -F ';' '{ print $2 }' )
    regex=$( echo $val | awk -F ';' '{ print $3 }' )

    store_vault "$key" "$pass" "$regex"
  done
fi

# From joined list in var

if [ -n "$CONF_LIST" ]; then
  for item in $CONF_LIST; do
    type=$( echo $item | awk -F ';' '{ print $1 }' )
    key=$( echo $item | awk -F ';' '{ print $2 }' )
    key_val=$( echo $item | awk -F ';' '{ print $3 }' )
    key_arg=$( echo $item | awk -F ';' '{ print $4 }' )

    if [ "$type" = 'consul' ]; then
      status_consul
      store_consul "$key" "$key_val"
    elif [ "$type" = 'consul_acl' ]; then
      status_consul
      store_consul_acl "$key" "$key_val" "$key_arg"
    elif [ "$type" = 'vault' ]; then
      status_vault
      store_vault "$key" "$key_val" "$key_arg"
    fi
  done
fi

while true; do
  sleep 5
done
