#!/bin/bash

for i in `find keychaineditor/var/jb/usr -type f -not -path '*/\.*'`;
do codesign -s 'Apple Development: Yufeng Zheng (NG7VYZWX67)' --entitlements src/entitlements.xml -f "$i"; done
