#!/bin/bash

iterations=4096
digest_len=32
salt_size=16
bash_escapes=false

b64enc() {
    echo -n "$1" | openssl base64
}

hmac_sum() {
    data=$1
    key=$2
    echo -n "$data" | openssl dgst -sha256 -mac HMAC -macopt hexkey:$key -binary | xxd -p | tr -d '[:space:]'
}

gen_salt() {
    salt_length=0
    while [ $salt_length -lt 25 ]
    do
        salt=$(openssl rand -hex $salt_size)
        salt_length=$(echo $(b64enc $(echo $salt | xxd -r -p | tr -d '\0')) | wc -c)
    done
    echo $salt
}

pbkdf2() {
    passwd=$1
    salt=$2
    openssl kdf -keylen ${digest_len} -kdfopt digest:SHA256 -kdfopt pass:${passwd} -kdfopt salt:$(echo "$salt"|xxd -r -p) -kdfopt iter:${iterations} PBKDF2  | tr -d ':' | tr '[:upper:]' '[:lower:]'
}

binary_b64enc() {
    hex=$1
    echo -n "$hex" | xxd -r -p | openssl base64
}

scram_sha256() {
    salt=$(gen_salt)
    digest_key=$(pbkdf2 "${passwd}" "${salt}")
    server_key=$(hmac_sum "Server Key" "${digest_key}")
    client_key=$(hmac_sum "Client Key" "${digest_key}")
    stored_key=$(echo -n ${client_key} | xxd -r -p | openssl dgst -sha256 -binary | xxd -p | tr -d '[:space:]')
    es=""
    if [ "${bash_escapes}" = true ]; then
        es="\\"
    fi
    printf "SCRAM-SHA-256${es}$%d:%s${es}$%s:%s\n" "${iterations}" "$(binary_b64enc "${salt}")" "$(binary_b64enc "${stored_key}")" "$(binary_b64enc "${server_key}")"
}

print_usage() {
    echo "Usage: provide single password argument to encrypt with scram-sha256"
    exit 1
}

main() {
    if [ $# -eq 1 ]; then
        passwd="$1"
    else
        print_usage
    fi

    if [ -z "$passwd" ]; then
        print_usage
    fi

    scram_sha256 "$passwd"
}

if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
    main "$@"
fi
