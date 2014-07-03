#!/bin/bash

VERSION=`uname -r`
HOSTNAME=`hostname`
DATE=`date +%Y%m%d`

if [[ $EUID -ne 0 ]]; then
    echo "This script must be run as root or with sudo root privileges"
    exit 1
fi

echo "Compiling LiME..." | tee -a ${HOSTNAME}.${DATE}.log
echo "" | tee -a ${HOSTNAME}.${DATE}.log
cd lime-forensics/src
make >> ${HOSTNAME}.${DATE}.log 2>&1
cp lime-${VERSION}.ko ../..
cd ../..

echo "Acquiring memory..." | tee -a ${HOSTNAME}.${DATE}.log
echo "" | tee -a ${HOSTNAME}.${DATE}.log
insmod ./lime-${VERSION}.ko format=lime path=./memdump.lime >> ${HOSTNAME}.${DATE}.log 2>&1
rmmod lime >> ${HOSTNAME}.${DATE}.log 2>&1

echo "Creating Volatility profile..." | tee -a ${HOSTNAME}.${DATE}.log
echo "" | tee -a ${HOSTNAME}.${DATE}.log
cd volatility/tools/linux
make >> ${HOSTNAME}.${DATE}.log 2>&1
echo $?
cd ../../..
sudo zip ${VERSION}.zip volatility/tools/linux/module.dwarf /boot/System.map-$VERSION >> ${HOSTNAME}.${DATE}.log 2>&1

echo "Creating LR bundle..." | tee -a ${HOSTNAME}.${DATE}.log
echo "" | tee -a ${HOSTNAME}.${DATE}.log
sudo zip ${HOSTNAME}.${DATE}.zip ${VERSION}.zip lime-${VERSION}.ko memdump.lime >> ${HOSTNAME}.${DATE}.log 2>&1

echo "Cleaning up..." | tee -a ${HOSTNAME}.${DATE}.log
echo "" | tee -a ${HOSTNAME}.${DATE}.log
rm -rf ${VERSION}.zip lime-${VERSION}.ko memdump.lime >> ${HOSTNAME}.${DATE}.log 2>&1
