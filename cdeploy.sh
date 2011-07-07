#!/bin/sh

echo "Creating tar..."
tar cJf dgi.tar.xz bin/dgi
echo ""

echo "Sizes:"
du -hs bin/dgi dgi.tar.xz
echo ""

echo "Copying tar to remote server..."
scp dgi.tar.xz jachapmanii:~/
echo ""

echo "Executing cdeploy_dgi on remote server..."
ssh jachapmanii ~/bin/cdeploy_dgi
echo ""

echo "Done."

