#!/bin/bash
mysql --protocol=socket --user=root --password="$MYSQL_ROOT_PASSWORD" <<EOF
CREATE DATABASE IF NOT EXISTS \`postfix\`;
CREATE USER 'postfix'@'%' IDENTIFIED BY '$MYSQL_POSTFIX_PASSWORD';
GRANT ALL ON \`postfix\`.* TO 'postfix';
EOF
