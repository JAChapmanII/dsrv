#!/bin/sh

echo "MD5 summing..."
md5sum bin/dgi.old > old.md5sum
echo ""

echo "Creating patch..."
time bsdiff bin/dgi.old bin/dgi dgi.bspatch
echo ""

echo "Sizes:"
du -hs bin/dgi.old bin/dgi dgi.bspatch
echo ""

echo "Copying patch/md5sum to remote server..."
scp dgi.bspatch old.md5sum jachapmanii:~/
echo ""

echo "Executing deploy_dgi on remote server..."
ssh jachapmanii ~/bin/deploy_dgi
echo ""

echo "Done."

