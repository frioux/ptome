#!/bin/bash
rm -f tome.tar.gz
cd ../../
export BUILD_NUM=`svn info | grep "Last Changed Rev" | awk -F' ' '{print $4}'`
cp header.php header.php.orig
sed 's/\[\[BUILD_TIME\]\]/'$BUILD_NUM'/g' header.php.orig > header.php
tar -czf tome.tar.gz *
mv header.php.orig header.php
mv tome.tar.gz admin/scripts/tome.tar.gz
cd admin/scripts/
scp -P 7822 tome.tar.gz letuacm@letuacm.org:projects/tome3
ssh letuacm@letuacm.org -p 7822 'cd projects/tome3; tar -xzf tome.tar.gz; rm tome.tar.gz'
