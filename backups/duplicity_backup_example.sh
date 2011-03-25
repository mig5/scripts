#!/bin/bash

#    Example duplicity backup script using Rackspace Cloud Files
#
#    Copyright (C) 2010 Miguel Jacq
#
#    This program is free software: you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation, either version 3 of the License, or
#    (at your option) any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License
#    along with this program.  If not, see http://www.gnu.org/licenses/.

SERVER=`uname -n`

export CLOUDFILES_USERNAME=johndoe

export CLOUDFILES_APIKEY=123456789012345678901234567890

export PASSPHRASE=secretpassphrasetoencryptbackups

options="--full-if-older-than 1M --exclude-other-filesystems" 


DIRS=(
  bin
  boot
  etc
  home
  lib
  root
  sbin
  usr
)

for dir in ${DIRS[@]}; do
  # Name of the container
  CLOUD_CONTAINER=${SERVER}_$dir

  echo "Backing up /$dir..."

  # A special clause for /root. We don't want the local duplicity cache data
  if [ $dir = "root" ]; then
    extra_options="--exclude /root/.cache"
  fi

  # Do the backup
  duplicity $options $extra_options /$dir cf+http://${CLOUD_CONTAINER}

  unset extra_options

  # Do some maintenance on the remote end to clean up old backups
  post_options="remove-older-than 3M --force"
  duplicity $post_options cf+http://${CLOUD_CONTAINER}
done
