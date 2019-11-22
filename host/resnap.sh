#!/usr/bin/env bash

# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
# Author        : Evan Widloski <evan@evanw.org>,
#
# Description   : Host sided script for screenshotting the current reMarkable display
#
# Dependencies  : pv, ssh, ffmpeg
#
# Thanks to https://github.com/canselcik/libremarkable/wiki/Framebuffer-Overview


# Current version (MAJOR.MINOR)
VERSION="1.0"

# Usage
function usage {
  echo "Usage: resnap.sh [-h | --help] [-v | --version] [-r ssh_address] [output_png]"
  echo
  echo "Arguments:"
  echo -e "output_png\tFile to save screenshot to (default resnap.png)"
  echo -e "-v --version\tDisplay version and exit"
  echo -e "-i\t\tpath to ssh pubkey"
  echo -e "-r\t\tAddress of reMarkable (default 10.11.99.1)"
  echo -e "-h --help\tDisplay usage and exit"
  echo
}

# default ssh address
ADDRESS=10.11.99.1
# default output file
OUTPUT=resnap.png

PARAMS=""
while (( "$#" )); do
  case "$1" in
    -r)
      ADDRESS=$2
      shift 2
      ;;
    -i)
        SSH_OPT="-i $2"
        shift 2
        ;;
    -h|--help)
        shift 1
        usage
        exit 1
        ;;
    --) # end argument parsing
      shift
      break
      ;;
    -*|--*=) # unsupported flags
      echo "Error: Unsupported flag $1" >&2
      usage
      exit 1
      ;;
    *) # preserve positional arguments
      OUTPUT=$1
      shift
      ;;
  esac
done

# check if ffmpeg installed
hash ffmpeg > /dev/null
if [ $? -eq 1 ]
then
    echo "Error: Command 'ffmpeg' not found."
    exit 1
fi

# check if pv installed
hash pv > /dev/null
if [ $? -eq 1 ]
then
    STAT=cat
else
    STAT="pv -W -s 10800000"
fi

# grab framebuffer from reMarkable
ssh root@$ADDRESS $SSH_OPT "cat /dev/fb0" | $STAT | \
    ffmpeg -y -loglevel quiet \
           -f rawvideo -pix_fmt gray16le -s 1408,1872 \
           -i - -vframes 1 "$OUTPUT"
