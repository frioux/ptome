#!/bin/bash
echo "Enter the password for mysql's root user";
mysql -p -h localhost -u root TOME < ../../dbstructure.sql
php dbConverter.php