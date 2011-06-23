from fabric.api import *
import os, sys, socket, datetime, time

def sshagent_run(cmd):
  """
  Helper function.
  Runs a command with SSH agent forwarding enabled.
    
  Note:: Fabric (and paramiko) can't forward your SSH agent. 
  This helper uses your system's ssh to do so.
  """

  for host in env.hosts:
    # catch the port number to pass to ssh
    print local('ssh-agent bash -c \'ssh-add; ssh -A %s "%s"\'' % (host, cmd))

# Take a database backup
def backup_db(repo, build):
  print "===> Ensuring backup directory exists"
  sshagent_run("mkdir -p /home/jenkins/dbbackups")
  print "===> Taking a database backup..."
  now = datetime.datetime.now()
  timestamp = now.strftime("%Y%m%d_%H%M%S")
  sshagent_run("cd /var/www/live.%s/www/sites/default && drush sql-dump | bzip2 > /home/jenkins/dbbackups/%s_%s.bz2" % (repo, repo, timestamp))

# Git clone the repo to /var/www/project-BUILD_TAG
def clone_repo(repo, build):
  print "===> Cloning %s from github" % repo
  sshagent_run("sudo git clone git@github.com:mig5/%s /var/www/%s_%s" % (repo, repo, build))

# Run a drush status against that build 
def drush_status(repo, build):
  print "===> Running a drush status test"
  sshagent_run("cd /var/www/%s_%s/www/sites/default && drush status" % (repo, build))


# Run drush updatedb to apply any database changes from hook_update's
def drush_updatedb(repo, build):
  print "===> Running any database hook updates"
  sshagent_run("cd /var/www/%s_%s/www/sites/default && drush updatedb -y" % (repo, build))


# Adjust symlink in /var/www/project to point to the new build
def adjust_symlink(repo, build):
  print "===> Removing current symlink to previous live codebase"
  sshagent_run("sudo unlink /var/www/live.%s" % repo)
  print "===> Setting new symlink to new live codebase"
  sshagent_run("sudo ln -s /var/www/%s_%s /var/www/live.%s" % (repo, build, repo))
  #sudo("/etc/init.d/nginx restart")

