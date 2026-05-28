ls -la
cd documents
cat notes.txt
cd ..
nmap 10.13.37.1
ssh root@10.13.37.1
cd tools
./scan.sh 10.13.37.0/24
grep -r "password" /etc
cat /etc/passwd
cd ~/projects
ls
cat keylogger.py
chmod +x scan.sh
./scan.sh
cd ~/downloads
ls -la
cd ..
cat documents/URGENT.txt