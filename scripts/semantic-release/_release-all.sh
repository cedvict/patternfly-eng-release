#!/bin/sh

default()
{
  # Add paths to env (non-Travis build)
  if [ -z "$TRAVIS" ]; then
    PATH=/usr/local/bin:/usr/bin:/bin:$PATH
    export PATH
  fi

  SCRIPT=`basename $0`
  SCRIPT_DIR=`dirname $0`
  SCRIPT_DIR=`cd $SCRIPT_DIR; pwd`

  . $SCRIPT_DIR/../_env.sh
  . $SCRIPT_DIR/../_common.sh
  . $SCRIPT_DIR/_common.sh

  BUILD_DIR=$TRAVIS_BUILD_DIR
  VERSION=`npm show patternfly version`
}

# Add tag to kick off version bump
#
# $1: Remote repo
# $2: Remote branch
# $3: Local branch
add_bump_tag()
{
  echo "*** Adding version bump tag"
  cd $BUILD_DIR

  # Add tag to kick off version bump
  git fetch $1 $2:$3 # <remote-branch>:<local-branch>
  check $? "git fetch failure"
  git checkout $3
  git tag $BUMP_CHAIN_TAG_PREFIX$VERSION -f
  git push $1 tag $BUMP_CHAIN_TAG_PREFIX$VERSION
  check $? "git push tag failure"
}

# Check prerequisites before continuing
#
prereqs()
{
  echo "*** This build is running against $TRAVIS_REPO_SLUG"

  # Ensure release runs for main PatternFly repo only
  if [ "$TRAVIS_REPO_SLUG" != "$REPO_SLUG_PTNFLY" ]; then
    check 1 "Release must be performed on $REPO_SLUG_PTNFLY only!"
  fi

  git tag | grep "^$RELEASE_TAG_PREFIX$VERSION$"
  if [ $? -eq 0 ]; then
    check 1 "Tag $RELEASE_TAG_PREFIX$VERSION exists. Do not release!"
  fi
}

usage()
{
cat <<- EEOOFF

    This script is a wrapper for the legacy release-all.sh script to automate releases using the latest version of
    PatternFly $VERSION

    sh [-x] $SCRIPT [-h] -o|r

    Example: sh $SCRIPT -o|r

    OPTIONS:
    h       Display this message (default)
    o       PatternFly Org
    r       RCUE

EEOOFF
}

# main()
{
  default

  if [ "$#" -eq 0 ]; then
    usage
    exit 1
  fi

  while getopts hor c; do
    case $c in
      h) usage; exit 0;;
      o) PTNFLY_ORG=1;
         SWITCH=-o;;
      r) RCUE=1;
         SWITCH=-r;;
      \?) usage; exit 1;;
    esac
  done

  prereqs # Check for existing tag before fetching remotes
  git_setup

  if [ -n "$PTNFLY_ORG" ]; then
    add_bump_tag $REPO_NAME_PTNFLY_ORG $RELEASE_BRANCH $RELEASE_BRANCH-$REPO_NAME_PTNFLY_ORG
  fi
  if [ -n "$RCUE" ]; then
    add_bump_tag $REPO_NAME_RCUE $RELEASE_BRANCH $RELEASE_BRANCH-$REPO_NAME_RCUE
  fi
}
