#!/bin/bash

echo "Enter the password for the tome user:"
pg_dump --no-owner -U tome tome > tomebackup.sql
