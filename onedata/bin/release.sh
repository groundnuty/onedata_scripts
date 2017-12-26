#!/usr/bin/env bash

# This script is used to update tags in compose files across scenarios

# Error handling.
# $1 - error string
die() {
  echo "${0##*/}: error: $*" >&2
  exit 1
}

command_exists() {
  command -v "$@" > /dev/null 2>&1
}

usage() { cat <<EOF
Usage: ${0##*/}

This script is used to upgrade docker images on this repo and release new version.
It has to be run from branch 'release/<version>'. It then:
- retags all images using bin/retag.sh script 
- commits the changes 
- creates a tag <version> 
- pushes everything to github (including tags)
- creates a pull request on github
EOF
}

main() {

  current_branch_name=$(git symbolic-ref HEAD | sed 's!refs\/heads\/!!')
  if ! [[ $current_branch_name =~ release/.+ ]]; then
    echo "This script needs to be invoked on a release branch, with name conforming to pattern: 'release/<release-name>''"
    exit 1
  fi
  tag=${current_branch_name#release/}

  should_we_continue=""
  should_we_continue_default="y"
  echo "This command will replace all docker image tags with a tag '$tag', create git tag of the same name, commit, push changes to git and create a pull request for you. "
  while [ "$should_we_continue" != "n" ] && [ "$should_we_continue" != "y" ] ; do
      read -p  "Do you want to continue? (y/n, default: $should_we_continue_default): " -r should_we_continue
      [  "$should_we_continue" == "" ] && should_we_continue=$should_we_continue_default
  done
  if [ "$should_we_continue" == "n" ]; then
    exit 0
  fi

  if ! command_exists hub; then
    echo "hub command not found! (https://github.com/github/hub).\n" >&2
    usage
    exit 1
  fi

  if ! command_exists hub; then
    echo "hub command not found! (https://github.com/github/hub).\n" >&2
    usage
    exit 1
  fi

  if command_exists ./retag.sh ; then
    retag="retag.sh"
  elif command_exists bin/retag.sh ; then 
    retag="bin/retag.sh"
  else 
    echo "retag.sh command not found!" >&2
    usage
    exit 1
  fi

  while (( $# )); do
      case $1 in
          -h|-\?|--help)   # Call a "usage" function to display a synopsis, then exit.
              usage
              exit 0
              ;;
      esac
      shift
  done

  docker_hub_org="onedata"
  $retag --oz-to $docker_hub_org/onezone:$tag --op-to $docker_hub_org/oneprovider:$tag --oc-to $docker_hub_org/oneclient:$tag

  if find "$(git rev-parse --show-toplevel)" -name "*.yml" | grep '.' ; then
    find "$(git rev-parse --show-toplevel)" -name "*.yml" | xargs git add
  else
    echo "No files to commit!" ; 
    exit 1
  fi
  git status

  git commit -m "updated docker image tags to $tag"
  git tag "$tag"
  git push --tags

  hub pull-request -m "Releasing Onedata $tag. Updated docker image tags to $tag."

  exit 0
}

main "$@"
