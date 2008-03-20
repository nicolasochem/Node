create_iso() {
    KICKSTART=ovirt-`uname -i`.ks
    if [ $# -eq 0 ]; then
	LABEL=ovirt-`date +%Y%m%d%H%M`
	/usr/bin/livecd-creator -c $KICKSTART -f $LABEL 1>&2 &&
	echo $LABEL.iso
    elif [ $# -eq 1 ]; then
	/usr/bin/livecd-creator -c $KICKSTART -b $1 1>&2 &&
	echo $1
    else
	return 1
    fi
}
