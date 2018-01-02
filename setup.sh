#! /bin/bash

# checking passed variables
if [ "$user" == "root" ]; then
	echo "No user variable...exiting"
	exit 1
fi
echo "User: $user"

if [ $uid -eq 0 ]; then
	echo "No uid variable...exiting"
	exit 1
fi
echo "UID: $uid"

if [ $gid -eq 0 ]; then
	echo "No gid variable...exiting"
	exit 1
fi
echo "GID: $gid"

if [ "$group" == "root" ]; then
	echo "No group name provided...setting group to G-$gid"
	group="G-$gid"
fi
echo "Group: $group"

# add user
echo "$user::$uid:$gid::/home/$user:/bin/bash" >> /etc/passwd

# add group
echo "$group:x:$gid:$user" >> /etc/group

# set sudo permissions
echo "$user ALL=(ALL) NOPASSWD:ALL" >> etc/sudoers

# set home
mkdir /home/$user
chown $user /home/$user
