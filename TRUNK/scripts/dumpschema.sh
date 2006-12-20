#!/bin/bash

echo "Enter the password for the tome user:"
pg_dump --no-owner --schema-only -U tome tome > tomeschema.sql
