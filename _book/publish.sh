git checkout build
gitbook init
gitbook install
gitbook build
git add .
git commit -m 'update gitbook'
git push origin build
git checkout master
rm -rf *
git checkout build -- _book
mv _book/* ./
rm -rf _book
rm -rf publish.sh
git add .
git commit -m 'publish gitbook'
git push origin master
git checkout build