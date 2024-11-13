########################
#####     Zeek     #####
########################

# dot sourcing variables
. "C:\WOLF\Scripts\Var.ps1"

wsl -u root -- apt-get install libmaxminddb-dev
wsl -u root /bin/bash -c "echo 'deb http://download.opensuse.org/repositories/security:/zeek/xUbuntu_22.04/ /' | sudo tee /etc/apt/sources.list.d/security:zeek.list"
wsl -u root /bin/bash -c "curl -fsSL https://download.opensuse.org/repositories/security:zeek/xUbuntu_22.04/Release.key | gpg --dearmor | sudo tee /etc/apt/trusted.gpg.d/security_zeek.gpg > /dev/null"
wsl -u root -- apt update -y
wsl -u root -- apt install zeek -y
wsl -u root /bin/bash -c "export PATH=/opt/zeek/bin:$PATH"
wsl -u root /bin/bash -c "mkdir /var/lib/GeoIP"

#install thrid party package
wsl -u root -- /opt/zeek/bin/zkg install zeek/brimsec/geoip-conn --force
wsl -u root -- /opt/zeek/bin/zeekctl deploy

###################################
#####     GEOIP databases     #####
###################################

wsl -u root -- cp -f /mnt/c/WOLF/GeoIP/GeoLite2-City.mmdb /var/lib/GeoIP/GeoLite2-City.mmdb
wsl -u root -- cp -f /mnt/c/WOLF/GeoIP/GeoLite2-Country.mmdb /var/lib/GeoIP/GeoLite2-Country.mmdb
wsl -u root -- cp -f /mnt/c/WOLF/GeoIP/GeoLite2-ASN.mmdb /var/lib/GeoIP/GeoLite2-ASN.mmdb