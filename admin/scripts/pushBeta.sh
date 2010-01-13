#!/bin/bash
rm -f tome.tar.gz
cd ../../
tar -czf tome.tar.gz *
mv tome.tar.gz admin/scripts/tome.tar.gz
cd admin/scripts/
scp tome.tar.gz dorm41@dorm41.org:tome.dorm41.org
ssh dorm41@dorm41.org 'cd tome.dorm41.org; tar -xzf tome.tar.gz; rm tome.tar.gz'
