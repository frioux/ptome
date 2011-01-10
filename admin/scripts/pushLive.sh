#!/bin/bash
rm -f tome.tar.gz
cd ../../
export BUILD_NUM=`svn info -r HEAD | grep "Last Changed Rev" | awk -F' ' '{print $4}'`
cp header.php header.php.orig
sed 's/\[\[BUILD_TIME\]\]/'$BUILD_NUM'/g' header.php.orig > header.php
tar -czf tome.tar.gz *
mv header.php.orig header.php
mv tome.tar.gz admin/scripts/tome.tar.gz
cd admin/scripts/
scp tome.tar.gz wharf_41@letuacm.org:letuacm.org/tome
ssh wharf_41@letuacm.org 'cd letuacm.org/tome; tar -xzf tome.tar.gz; rm tome.tar.gz'
