#!/bin/bash
set -e
if command -v dnf &> /dev/null; then
    dnf update -y
    dnf install -y httpd
else
    yum update -y
    yum install -y httpd
fi
