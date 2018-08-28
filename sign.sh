#!/bin/bash

for i in `find keychaineditor/usr -type f -not -path '*/\.*'`;
do codesign -s 'iPhone Developer: fartumlagigle2@gmail.com (P3YZJ8Q6SH)' --entitlements src/entitlements.xml -f "$i"; done
