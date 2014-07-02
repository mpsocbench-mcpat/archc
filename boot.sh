#!/bin/sh
test -d config || mkdir config
autoheader
aclocal
libtoolize --version &> /dev/null
if [ $? -eq 0 ]; then
    libtoolize --force --copy
else
    libtoolize --force --copy
fi
automake --add-missing --copy
autoconf
