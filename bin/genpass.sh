#!/usr/bin/env bash

echo "Please enter password to hash:"
read -p "> " pass
echo ""
hash="$(echo "${pass}" | md5sum | awk '{print $1}')"
hash2="$(echo "${hash}" | md5sum | awk '{print $1}')"
echo "Hash of \"${pass}\": ${hash}${hash2}"
echo ""
exit 0
