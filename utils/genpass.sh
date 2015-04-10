#!/usr/bin/env bash

echo "Please enter password to hash:"
read -p "> " pass
echo ""
hash="$(echo -n "${pass}" | sha256sum | awk '{print $1}')"
echo "Hash of \"${pass}\": ${hash}"
echo ""
