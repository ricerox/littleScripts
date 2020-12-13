#!/usr/bin/env bash

############################################################
#                        DISCLAIMER                        #
#                  This is an old version                  #
#             This one should not be published             #
#          The new version is currently worked on          #
############################################################

#
# Copyright 2019 pixELSflash
#
# Author: pixELSflash
# Purpose: play radio in the terminal with one command
#

errorColor="$(tput setaf 9)"
resetColor="$(tput sgr0)"
echo >&2 "${errorColor}This is an old version!${resetColor}"
echo >&2 "${errorColor}You should use the newer one!${resetColor}"

# if no arguments are given echo the usage and exit
if [[ $# < 1 ]]; then
	echo >&2 "usage: $0 [stop] [info] [radioStation [inBackground]]"
	exit 1
fi

programMode="$1"

vlcPidTmpFile="/tmp/playRadio_vlcPID"

if [[ -f "${vlcPidTmpFile}" ]]; then
	read -r -a streamInfos <<<"${vlcPidTmpFile}"
	pidOfVLC="${streamInfos[0]}"
	unset streamInfos[0]
	radioInfo="${streamInfos[0]}"
fi

if [[ "${programMode}" == "info" ]]; then
	echo "You are currently listening to: ${radioInfo}"
	exit 0
fi


# if the first argument is "stop"
# get the PID of the VLC media player and kill it
if [[ "${programMode}" == "stop" ]]; then
	if [[ -f ${vlcPidTmpFile} ]]; then
		kill "${pidOfVLC}" && echo "radio stopped"
		# remove file so we know that the VLC media player was stopped
		rm "${vlcPidTmpFile}"
		exit 0
	else
		echo >&2 "No radio stream was started"
		exit 2
	fi
fi

# if the vlcPidTmpFile exists this indicates that there
# is already an instance of the VLC media player running
# if this is the case we do not want to start another instance
if [[ -f "${vlcPidTmpFile}" ]]; then
	echo >&2 "Radio is already turned on"
	echo >&2 "First stop the current radio stream before starting another stream"
	exit 2
fi

# if the second argument does not exist
# it is a shortcut for
# playRadio [radioStation] true
# so it gets set to "true"
secondArgument="${2}" # HACK: if you just put 2 in the line below it does not work
inBackground="${secondArgument:="true"}"
# create this variable for better readability
radioStation="${programMode}"

radioStationInfo=""

# check which radio station is selected and put the particular
# internet address into $radioStationUrl
# if the given radioStation is not known just use the argument as the URL
# List of radio stations: https://www.radio-browser.info/
case "${radioStation}" in
	"swr3" | "SWR3" | "Swr3" )
		radioStationUrl="http://swr-swr3-live.cast.addradio.de/swr/swr3/live/mp3/64/stream.mp3"
		radioStationInfo="SWR3"
		;;
	"radioSiegen" | "RadioSiegen" | "radiosiegen" | "Siegen" | "siegen" )
		radioStationUrl="http://dg-ais-eco-http-fra-eco-cdn.cast.addradio.de/radiosiegen/live/mp3/high"
		radioStationInfo="Radio Siegen"
		;;
	* )
		# VLC media player needs http:// in front of an URL
		# so we check whether it is already given or not
		# Depending on this we set "http://" in front of the "URL"
		if [[ "${radioStation}" == "http"* ]]; then
			radioStationUrl="${radioStation}"
		else
			radioStationUrl="http://${radioStation}"
		fi
		radioStationInfo="${radioStationUrl}"
		;;
esac
# either play radio in background (cvlc)
# or in foreground with an interface
if [[ "${inBackground}" == "true" ]]; then
	cvlc --quiet "${radioStationUrl}" &

	# get the PID of the last started background process (cvlc)
	playRadio_vlcPID="$!"
	# remember this PID in the file /tmp/playRadio_vlcPID
	# and put the radio station name to the end
	echo ${playRadio_vlcPID} >"${vlcPidTmpFile}"
	echo ${radioStationInfo} >>"${vlcPidTmpFile}"
else
	vlc "${radioStationUrl}"
fi
