#!/bin/sh

######################################################################
## Basic Aegir bulk backup script.                                  ##
## For Aegir version 0.4alpha3 and Drush <= 2.1                     ##
## Copyright 2010 Miguel Jacq                                       ## 
## mig@mig5.net www.mig5.net                                        ##
##                                                                  ##
## This script is free software licensed under the GPL v3.          ##
## No warranty is provided and the author claims no responsibility  ##
## for any disasters caused during the execution of this script.    ##
## Backup first! Isn't that ironic? :)                              ##
##                                                                  ##
##                                                                  ##
##                           INSTRUCTIONS                           ##
##                                                                  ##
## If this file is named 'backup.sh', then run the                  ##
## script as the 'aegir' user by typing                             ##
## 'sh backup.sh' or simply './backup.sh' if the file               ##
## is already executable.                                           ##
##                                                                  ##
## Below are some variables that you may need to change             ##
##                                                                  ##
######################################################################

# Aegir home directory. No trailing slash.
HOME="/var/aegir"

# Path to the Drush executable.
DRUSH="$HOME/drush/drush.php"

# Path to the config directory. No trailing slash.
CONFIG_DIR="$HOME/config"

# Path to the vhost.d directory where vhost configs are stored. No trailing slash.
VHOSTS="$CONFIG_DIR/vhost.d"

# Be verbose? 0 = no, 1 = yes 
VERBOSE=0

# Add debug information? (overrules VERBOSE) 0 = no, 1 = yes
DEBUG=0

######################################################################
##                                                                  ##
##      You should not need to change anything below this line      ##
##                                                                  ##
######################################################################


# Do the backup
for vhost in `find $VHOSTS -type f`; do
  site=`grep -m 1 ServerName ${vhost} | awk '{print $2}'`
  root=`grep -m 1 DocumentRoot ${vhost} | awk '{print $2}'`
 
  if [ -n "$site" ]; then
    CMD="$DRUSH --root=$root provision backup $site"

    if [ "$DEBUG" -eq 1 ]; then
      echo -e "Attempting to backup $site...\n"
      $CMD -d
      echo -e "...done.\n"

    elif [ "$VERBOSE" -eq 1 ]; then
      echo -e "Attempting to backup $site...\n"
      $CMD -v
      echo -e "...done.\n"

    else
      $CMD
    fi
  fi
done

