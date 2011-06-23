#!/bin/bash
#
# Wrapper script for our fabfile, to be called from Jenkins
#

# Where our fabfile is
FABFILE=/var/lib/jenkins/scripts/fab_deployment.py

# Array of tasks - these are actually functions in the fabfile, as an array here for the sake of abstraction
TASKS=(
  backup_db
  clone_repo
  drush_status
  drush_updatedb
  adjust_symlink
)

# Loop over each 'task' and call it as a function via the fabfile, 
# with some extra arguments (host, github repo name, build id), 
# which are sent to this shell script by Jenkins

for task in ${TASKS[@]}; do
  fab -f $FABFILE -H $1 $task:repo=$2,build=$3 || exit 1
done
