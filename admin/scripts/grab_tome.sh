#!/bin/sh
scp -P 7822 letuacm@letuacm.org:backups/tomedb-hourly.0 .
mv tomedb-hourly.0 tomedb-hourly.bz2