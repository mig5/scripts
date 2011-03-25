#!/bin/sh

############################################################
#  Aegir build script                                      #
#  Builds a platform from a supplied Drush make stub file  #
#  and saves/imports it into an Aegir system               #
#                                                          #
#  Written by Miguel Jacq (mig5) of Green Bee Digital      #
#  February 2011                                           #
############################################################

# The Aegir dir
AEGIR_HOME=$HOME

# The Drush executable
DRUSH="/var/aegir/drush/drush.php"

# Path to where the build (stub) makefiles are
BUILDREPO_DIR="/var/aegir/git/builds"

# Whether or not to use --working-copy to retain .git metadata. 1 is true, 0 is false
WORKING_COPY=1

# Any options to pass to Drush Make
DRUSH_MAKE_OPTIONS=""

# Try to force the dispatcher at the end (to speed things up in Aegir)?
FORCE_DISPATCH=1

# Run some dependency checks
dependencies() {
  # Make sure we are the aegir user
  if [ `whoami` != "aegir" ] ; then
    echo "This script should be ran as the aegir user."
    exit 1
  fi

  # we need to check both because some platforms (like SunOS) return 0 even if the binary is not found
  if which drush 2> /dev/null && which drush | grep -v 'no drush in' > /dev/null; then
    echo "Drush is in the path, good"
    DRUSH=drush
  elif [ -x $DRUSH ] ; then
    echo "Drush found in $DRUSH, good"
  else
    echo "Drush was not found in $DRUSH. Eek! Aborting."
    exit 1
  fi

  # Check for whether a buildfile was supplied, if not, let us select it
  if test -z "$1"
    then
      buildfiles=( `ls $BUILDREPO_DIR/` )
      echo "Please select a makefile to build from:"
      select buildfile in "${buildfiles[@]}"
    do
      BUILDFILE=$BUILDREPO_DIR/$buildfile
      PLATFORM_BUILD=${buildfile}_`date '+%Y%m%d%H%M%S'`
      break
    done
  else
    BUILDFILE=$BUILDREPO_DIR/$1
    # This will be the name of this specific build
    PLATFORM_BUILD=${1}_`date '+%Y%m%d%H%M%S'`
  fi

  if [ ! -f $BUILDFILE ]; then
    echo "$BUILDFILE does not exist! Aborting."
    exit 1
  else
    echo "Makefile $BUILDFILE found, good"
  fi

  # This will be the destination directory of the build
  PLATFORM_DIR=$AEGIR_HOME/platforms/$PLATFORM_BUILD

  # Check for whether a remote server was supplied, if not, let us select it
  # @TODO we need to ignore DB-only servers here..
  if test -z "$2"
    then
      servers=( `$DRUSH sa | grep server | grep -v localhost` )
      echo "Please select a server to build to:"
      select server in "${servers[@]}"
    do
      SERVER=$server
      break
    done
  else
    SERVER=$2
  fi
}

# Build the platform
platform_build() {
  $DRUSH make $BUILDFILE $PLATFORM_DIR $DRUSH_MAKE_OPTIONS
}

# Save the platform context
platform_save() {
  $DRUSH --root=$PLATFORM_DIR provision-save @${PLATFORM_BUILD} --context_type='platform' --makefile=$BUILDFILE --web_server=$SERVER
}

# Import the platform
platform_import() {
  $DRUSH @hostmaster hosting-import @${PLATFORM_BUILD}
}

echo "Running dependency checks..."
dependencies $1 $2

echo "Building the platform $PLATFORM_BUILD into $PLATFORM_DIR..."
platform_build

echo "Saving the platform context..."
platform_save

echo "Importing the platform into Aegir..."
platform_import

if [ $FORCE_DISPATCH -eq 1 ]; then
  $DRUSH @hostmaster hosting-dispatch
fi
