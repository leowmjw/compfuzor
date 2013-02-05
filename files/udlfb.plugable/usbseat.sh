#!/bin/bash
# takes the "seat number" as parameter $1
# the seat number is the kernel device id of the hub the seat's devices are sitting off of
# called once for every usb device that MIGHT be part of a seat, when they arrive or remove 

if [[ !(-n `/bin/pidof gdm`) ]]; then
    exit 0
fi

seat_running=`/usr/bin/gdmdynamic -l | /bin/sed -n -e "/:$1,/p"`

# $ACTION environment variable is set by udev subsystem
case "$ACTION" in
	'remove')
		if [[ -n "{$seat_running}" ]]; then
			/usr/bin/gdmdynamic -v -d $1
		fi
		;;
	*)
                # A device which might be part of a seat has been added

		# if we already have a running seat for this #, exit
		if [[ -n "${seat_running}" ]]; then
			exit 0
		fi

		if [[ -e /dev/usbseat/$1/keyboard && -e /dev/usbseat/$1/mouse && -e /dev/usbseat/$1/display ]]; then

			# We have a newly complete seat. Start it.
			TMPFILE=`/bin/mktemp` || exit 1
			/bin/sed "s/%ID_SEAT%/$1/g" < /lib/udev/usbseat-xf86.conf.sed > $TMPFILE
			/usr/bin/gdmdynamic -v -t 2 -s 1 -a "$1=/usr/X11R6/bin/X -br :$1 -audit 0 -nolisten tcp vt07 -config $TMPFILE"
			/usr/bin/gdmdynamic -v -r $1
		fi
		;;
esac

exit 0
