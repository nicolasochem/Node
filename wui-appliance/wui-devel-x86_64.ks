# Kickstart file automatically generated by anaconda.

install
url --url http://download.fedora.redhat.com/pub/fedora/linux/releases/8/Fedora/x86_64/os/
lang en_US.UTF-8
keyboard us
network --device eth0 --bootproto dhcp
rootpw  --iscrypted $1$HNOucon/$m69RprODwQn4XjzVUi9TU0
firewall --disabled
authconfig --enableshadow --enablemd5
selinux --disabled
services --disabled=iptables,yum-updatesd,libvirtd,bluetooth,cups,gpm,pcscd --enabled=ntpd,dhcpd,xinetd,httpd,postgresql,ovirt-wui,named
timezone --utc America/New_York
text
bootloader --location=mbr --driveorder=sda
# The following is the partition information you requested
# Note that any partitions you deleted are not expressed
# here so unless you clear all partitions first, this is
# not guaranteed to work
zerombr
clearpart --all --drives=sda
part /boot --fstype ext3 --size=100 --ondisk=sda
part pv.2 --size=0 --grow --ondisk=sda
volgroup VolGroup00 --pesize=32768 pv.2
logvol swap --fstype swap --name=LogVol01 --vgname=VolGroup00 --size=512
logvol / --fstype ext3 --name=LogVol00 --vgname=VolGroup00 --size=1024 --grow

repo --name=f8 --mirrorlist=http://mirrors.fedoraproject.org/mirrorlist?repo=fedora-8&arch=x86_64
repo --name=f8-updates --mirrorlist=http://mirrors.fedoraproject.org/mirrorlist?repo=updates-released-f8&arch=x86_64
repo --name=freeipa --baseurl=http://freeipa.com/downloads/devel/rpms/F7/x86_64/ --includepkgs=ipa*
repo --name=ovirt-management --baseurl=http://ovirt.et.redhat.com/repos/ovirt-management-repo/x86_64/

%packages
@admin-tools
@editors
@system-tools
@text-internet
@core
@base
@hardware-support
@web-server
@sql-server
@development-libs
@legacy-fonts
@development-tools
pax
imake
dhcp
tftp-server
tftp
dhclient
ipa-server
ipa-admintools
xinetd
libvirt
cyrus-sasl-gssapi
iscsi-initiator-utils
collectd
ruby-libvirt
ruby-postgres
ovirt-wui
firefox
xorg-x11-xauth
virt-viewer
bind
bind-chroot
emacs
git
ruby-devel
avahi-devel
livecd-tools
-libgcj
-glib-java
-valgrind
-boost-devel
-frysk
-bittorrent
-fetchmail
-slrn
-cadaver
-mutt

%post

cat > /etc/sysconfig/network-scripts/ifcfg-eth1 << \EOF
# Realtek Semiconductor Co., Ltd. RTL-8139/8139C/8139C+
DEVICE=eth1
BOOTPROTO=static
IPADDR=192.168.50.2
NETMASK=255.255.255.0
BROADCAST=192.168.50.255
HWADDR=00:16:3E:12:34:56
ONBOOT=yes
EOF

# make sure our "hostname" resolves to management.priv.ovirt.org
sed -i -e 's/^HOSTNAME.*/HOSTNAME=management.priv.ovirt.org/' /etc/sysconfig/network

cat > /etc/dhcpd.conf << \EOF
allow booting;
allow bootp;
ddns-update-style interim;
ignore client-updates;

option libvirt-auth-method code 202 = text;

subnet 192.168.50.0 netmask 255.255.255.0 {
        option domain-name "priv.ovirt.org";
        option domain-name-servers 192.168.50.2;
        next-server 192.168.50.2;
        option routers 192.168.50.1;
        option libvirt-auth-method "krb5:192.168.50.2:8089/config";
        filename "pxelinux.0";
        host node3 {
                fixed-address 192.168.50.3;
                hardware ethernet 00:16:3e:12:34:57;
        }
        host node4 {
                fixed-address 192.168.50.4;
                hardware ethernet 00:16:3e:12:34:58;
        }
        host node5 {
                fixed-address 192.168.50.5;
                hardware ethernet 00:16:3e:12:34:59;
        }
}
EOF

cat > /etc/sysconfig/dhcpd << \EOF
# Command line options here
DHCPDARGS="eth1"
EOF

cat > /var/named/chroot/etc/named.conf << \EOF
options {
        //listen-on port 53 { 127.0.0.1; };
        //listen-on-v6 port 53 { ::1; };
        directory       "/var/named";
        dump-file       "/var/named/data/cache_dump.db";
        statistics-file "/var/named/data/named_stats.txt";
        memstatistics-file "/var/named/data/named_mem_stats.txt";
        //allow-query     { localhost; };
        recursion yes;
        allow-transfer {"none";};
        allow-recursion {192.168.50.0/24; 127.0.0.1;};
        forward only;
        forwarders { 192.168.122.1; };
};

logging {
        channel default_debug {
                file "data/named.run";
                severity dynamic;
        };
};

zone "." IN {
        type hint;
        file "named.ca";
};

include "/etc/named.rfc1912.zones";

zone "priv.ovirt.org" {
        type master;
        file "priv.ovirt.org.zone";
};

zone "50.168.192.in-addr.arpa" {
        type master;
        file "50.168.192.in-addr.arpa.zone";
};
EOF

cat > /var/named/chroot/var/named/priv.ovirt.org.zone << \EOF
$TTL 86400
@       IN      SOA     @  management.priv.ovirt.org. (
                        28 ; serial
                        180 ; refresh
                        60 ; retry
                        604800 ; expire
                        60 ; ttl
                        )

@       IN      NS      management.priv.ovirt.org.

@       IN      MX      2       priv.ovirt.org.

@       IN      A       192.168.50.2

management      IN      A       192.168.50.2
node3           IN      A       192.168.50.3
node4           IN      A       192.168.50.4
node5           IN      A       192.168.50.5
EOF

cat > /var/named/chroot/var/named/50.168.192.in-addr.arpa.zone << \EOF
$TTL 86400
@       IN      SOA     @       management.priv.ovirt.org.   (
                                8 ; serial
                                28800 ; refresh
                                14400 ; retry
                                3600000 ; expire
                                86400 ; ttl
                                )

@               IN      NS      management.priv.ovirt.org.
2               IN      PTR     management.priv.ovirt.org.
3               IN      PTR     node3.priv.ovirt.org.
4               IN      PTR     node4.priv.ovirt.org.
5               IN      PTR     node5.priv.ovirt.org.
EOF

# with the new libvirt (0.4.0), make sure we we setup gssapi in the mech_list
if [ `egrep -c '^mech_list: gssapi' /etc/sasl2/libvirt.conf` -eq 0 ]; then
   sed -i -e 's/^\([[:space:]]*mech_list.*\)/#\1/' /etc/sasl2/libvirt.conf
   echo "mech_list: gssapi" >> /etc/sasl2/libvirt.conf
fi

# set up the yum repos
cat > /etc/yum.repos.d/freeipa.repo << \EOF
[freeipa]
name=FreeIPA Development
baseurl=http://freeipa.com/downloads/devel/rpms/F7/x86_64/
enabled=1
gpgcheck=0
EOF

cat > /etc/yum.repos.d/ovirt-management.repo << \EOF
[ovirt-management]
name=ovirt-management
baseurl=http://ovirt.et.redhat.com/repos/ovirt-management-repo/x86_64
enabled=1
gpgcheck=0
EOF

echo "0.fedora.pool.ntp.org" >> /etc/ntp/step-tickers

cat > /usr/share/ovirt-wui/psql.cmds << \EOF
CREATE USER ovirt WITH PASSWORD 'v23zj59an';
CREATE DATABASE ovirt;
GRANT ALL PRIVILEGES ON DATABASE ovirt to ovirt;
CREATE DATABASE ovirt_test;
GRANT ALL PRIVILEGES ON DATABASE ovirt_test to ovirt;
EOF
chmod a+r /usr/share/ovirt-wui/psql.cmds

sed -i -e 's/\(.*\)disable\(.*\)= yes/\1disable\2= no/' /etc/xinetd.d/tftp

# automatically refresh the kerberos ticket every hour (we'll create the
# principal on first-boot)
cat > /etc/cron.hourly/ovirtadmin.cron << \EOF
#!/bin/bash
/usr/kerberos/bin/kdestroy
/usr/kerberos/bin/kinit -k -t /usr/share/ovirt-wui/ovirtadmin.tab ovirtadmin@PRIV.OVIRT.ORG
EOF
chmod 755 /etc/cron.hourly/ovirtadmin.cron

cat > /root/create_default_principals.py << \EOF
#!/usr/bin/python

import krbV
import os, string, re
import socket
import shutil

def kadmin_local(command):
        ret = os.system("/usr/kerberos/sbin/kadmin.local -q '" + command + "'")
        if ret != 0:
                raise

default_realm = krbV.Context().default_realm

# here, generate the libvirt/ principle for this machine, necessary
# for taskomatic and host-browser
this_libvirt_princ = 'libvirt/' + socket.gethostname() + '@' + default_realm
kadmin_local('addprinc -randkey +requires_preauth ' + this_libvirt_princ)
kadmin_local('ktadd -k /usr/share/ovirt-wui/ovirt.keytab ' + this_libvirt_princ)

# We need to replace the KrbAuthRealms in the ovirt-wui http configuration
# file to be the correct Realm (i.e. default_realm)
ovirtconfname = '/etc/httpd/conf.d/ovirt-wui.conf'
ipaconfname = '/etc/httpd/conf.d/ipa.conf'

# make sure we skip this on subsequent runs of this script
if string.find(file(ipaconfname, 'rb').read(), '<VirtualHost *:8089>') < 0:
    ipaconf = open(ipaconfname, 'r')
    ipatext = ipaconf.readlines()
    ipaconf.close()

    ipaconf2 = open(ipaconfname, 'w')
    print >>ipaconf2, "Listen 8089"
    print >>ipaconf2, "NameVirtualHost *:8089"
    print >>ipaconf2, "<VirtualHost *:8089>"
    for line in ipatext:
        newline = re.sub(r'(.*RewriteCond %{HTTP_HOST}.*)', r'#\1', line)
        newline = re.sub(r'(.*RewriteRule \^/\(.*\).*)', r'#\1', newline)
        newline = re.sub(r'(.*RewriteCond %{SERVER_PORT}.*)', r'#\1', newline)
        newline = re.sub(r'(.*RewriteCond %{REQUEST_URI}.*)', r'#\1', newline)
        ipaconf2.write(newline)
    print >>ipaconf2, "</VirtualHost>"
    ipaconf2.close()

if string.find(file(ovirtconfname, 'rb').read(), '<VirtualHost *:80>') < 0:
    ovirtconf = open(ovirtconfname, 'r')
    ovirttext = ovirtconf.readlines()
    ovirtconf.close()

    ovirtconf2 = open(ovirtconfname, 'w')
    print >>ovirtconf2, "NameVirtualHost *:80"
    print >>ovirtconf2, "<VirtualHost *:80>"
    for line in ovirttext:
        newline = re.sub(r'(.*)KrbAuthRealms.*', r'\1KrbAuthRealms ' + default_realm, line)
        newline = re.sub(r'(.*)Krb5KeyTab.*', r'\1Krb5KeyTab /etc/httpd/conf/ipa.keytab', newline)
        ovirtconf2.write(newline)
    print >>ovirtconf2, "</VirtualHost>"
    ovirtconf2.close()
EOF
chmod +x /root/create_default_principals.py

# pretty login screen..

echo -e "" > /etc/issue
echo -e "           888     888 \\033[0;32md8b\\033[0;39m         888    " >> /etc/issue
echo -e "           888     888 \\033[0;32mY8P\\033[0;39m         888    " >> /etc/issue
echo -e "           888     888             888    " >> /etc/issue
echo -e "   .d88b.  Y88b   d88P 888 888d888 888888 " >> /etc/issue
echo -e "  d88''88b  Y88b d88P  888 888P'   888    " >> /etc/issue
echo -e "  888  888   Y88o88P   888 888     888    " >> /etc/issue
echo -e "  Y88..88P    Y888P    888 888     Y88b.  " >> /etc/issue
echo -e "   'Y88P'      Y8P     888 888      'Y888 " >> /etc/issue
echo -e "" >> /etc/issue
echo -e "  Admin node \\\\n " >> /etc/issue
echo -e "" >> /etc/issue
echo -e "  Virtualization just got the \\033[0;32mGreen Light\\033[0;39m" >> /etc/issue
echo -e "" >> /etc/issue

cp /etc/issue /etc/issue.net

# for firefox, we need to make some subdirs and add some preferences
mkdir -p /root/.mozilla/firefox/uxssq4qb.ovirtadmin
cat >> /root/.mozilla/firefox/uxssq4qb.ovirtadmin/prefs.js << \EOF
user_pref("network.negotiate-auth.delegation-uris", "priv.ovirt.org");
user_pref("network.negotiate-auth.trusted-uris", "priv.ovirt.org");
EOF

cat >> /root/.mozilla/firefox/profiles.ini << \EOF
[General]
StartWithLastProfile=1

[Profile0]
Name=ovirtadmin
IsRelative=1
Path=uxssq4qb.ovirtadmin
EOF

# make sure we use ourselves as the nameserver (not what we get from DHCP)
cat > /etc/dhclient-exit-hooks << \EOF
echo "search ovirt.org priv.ovirt.org" > /etc/resolv.conf
echo "nameserver 192.168.50.2" >> /etc/resolv.conf
EOF
chmod +x /etc/dhclient-exit-hooks

cat > /etc/init.d/ovirt-app-first-run << \EOF
#!/bin/bash
#
# ovirt-app-first-run First run configuration for Ovirt WUI appliance
#
# chkconfig: 3 99 01
# description: ovirt appliance first run configuration
#

# Source functions library
. /etc/init.d/functions

KADMIN=/usr/kerberos/sbin/kadmin.local

start() {
	echo -n "Starting ovirt-app-first-run: "
	(
	# set up freeipa
	/usr/sbin/ipa-server-install -r PRIV.OVIRT.ORG -p ovirtwui -P ovirtwui -a ovirtwui --hostname management.priv.ovirt.org -u admin -U

	# now create the ovirtadmin user
	$KADMIN -q 'addprinc -randkey ovirtadmin@PRIV.OVIRT.ORG'	
	$KADMIN -q 'ktadd -k /usr/share/ovirt-wui/ovirtadmin.tab ovirtadmin@PRIV.OVIRT.ORG'
	/etc/cron.hourly/ovirtadmin.cron

	/root/create_default_principals.py

	service postgresql initdb
	echo "local all all trust" > /var/lib/pgsql/data/pg_hba.conf
	echo "host all all 127.0.0.1 255.255.255.0 trust" >> /var/lib/pgsql/data/pg_hba.conf
	service postgresql start

	su - postgres -c "/usr/bin/psql -f /usr/share/ovirt-wui/psql.cmds"

	cd /usr/share/ovirt-wui ; rake db:migrate
	/usr/bin/ovirt_grant_admin_privileges.sh ovirtadmin
	) > /root/ovirt-app-first-run.log
	RETVAL=$?
	if [ $RETVAL -eq 0 ]; then
		echo_success
	else
		echo_failure
	fi
	echo
}

case "$1" in
  start)
        start
        ;;
  *)
        echo "Usage: ovirt {start}"
        exit 2
esac

/sbin/chkconfig ovirt-app-first-run off
EOF
chmod +x /etc/init.d/ovirt-app-first-run
/sbin/chkconfig ovirt-app-first-run on

# Finally, get the PXE boot image; note that this can take a while!
cd /tmp ; wget http://ovirt.org/download/ovirt-pxe-host-image-0.1.tar.bz2
tar -C / -jxvf /tmp/ovirt-pxe-host-image-0.1.tar.bz2

%end
