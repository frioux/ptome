#!/bin/bash
rm -f tome.tar.gz
cd ../../
tar -czf tome.tar.gz *
mv tome.tar.gz admin/scripts/tome.tar.gz
cd admin/scripts/
scp -P 7822 tome.tar.gz letuacm@letuacm.org:projects/tome3
ssh letuacm@letuacm.org -p 7822 'cd projects/tome3; tar -xzf tome.tar.gz; rm tome.tar.gz'
