#!/usr/bin/env bash

# This script is used to update tags in compose files across scenarios

# Error handling.
# $1 - error string
die() {
  echo "${0##*/}: error: $*" >&2
  exit 1
}

retag() {
	local component_name="$1"
	local full_name="$2"
	echo "Displaying all old tags for $component_name and runing test sed to see if they get replaced by $full_name"
	find . -type f -iname "docker-compose-*.yml" -exec grep -aHb --color -E "image:\s+\w+/$component_name:.*"  {} \;
	find . -type f -iname "docker-compose-*.yml" -exec sed  -n "s#image:\s\+\(\w\+\)/$component_name:.*#image: $full_name#gp" {} \;

	echo "Retaring and displaying changes"
	find . -type f -iname "docker-compose-*.yml" -exec sed -i "s#image:\s\+\(\w\+\)/$component_name:.*#image: $full_name#g" {} \;
	find . -type f -iname "docker-compose-*.yml" -exec grep -aHb --color -E "image:\s+$full_name"  {} \;
}

usage() { cat <<EOF
Usage: ${0##*/}  [-h] [--oz-to <onezone destination image+tag>] [--op-to <onezone destination image+tag>] [--oc-to <oneclient destination image+tag>]

Example usage:
${0##*/} --op-to "onedata/oneprovider:nightly-VFS-1" --oc-to "onedata/oneclient:nightly-VFS-2" --oc-to "onedata/oneclient:nightly-VFS-2" 

Options:
  -h,--help         print this help message
  --oz-to           a full domain name and tag of a destination Onezone image
  --op-to           a full domain name and tag of a destination Oneprovider image
  --oc-to           a full domain name and tag of a destination Oneclient image
EOF
}

main() {

  if (( ! $# )); then
    usage
  fi

  while (( $# )); do
      case $1 in
          -h|-\?|--help)   # Call a "usage" function to display a synopsis, then exit.
              usage
              exit 0
              ;;
          --oz-to)
              OZ_TO="$2"
              shift
              ;;
          --op-to)
              OP_TO="$2"
              shift
              ;;
          --oc-to)
              OC_TO="$2"
              shift
              ;;
          -?*)
              printf 'WARN: Unknown option (ignored): %s\n' "$1" >&2
              exit 1
              ;;
          *)
              die "no option $1"
              ;;
      esac
      shift
  done

  [[ ! -z "$OZ_TO" ]] && retag onezone "$OZ_TO"
  [[ ! -z "$OP_TO" ]] && retag oneprovider "$OP_TO"
  [[ ! -z "$OC_TO" ]] && retag oneclient "$OC_TO"

  exit 0
}

main "$@"