#!/bin/sh

echo 'lsb_release -a : \n'
lsb_release -a
echo '\nuname -m && cat /etc/*release : \n'
uname -m && cat /etc/*release
echo '\nuname -srmv : \n'
uname -srmv

