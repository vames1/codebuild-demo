#!/bin/bash
set -e
systemctl start httpd
systemctl enable httpd
