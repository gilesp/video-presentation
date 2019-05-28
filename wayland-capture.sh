#!/bin/bash

#
# A script to capture the desktop via the wayland drm/kms pipeline.
#
# Currently requires running as root, to access the
# /dev/dri/renderD128 device. Although I think you could add your
# current user to the video group instead. Another option is to use
# setcap and permit ffmpeg to access the device: sudo setcap
# cap_sys_admin+ep /path/to/ffmpeg
#
# Uses vaapi hardware accelleration to avoid your machine grinding to
# a halt.
#

# TODO: Figure out how to list available crtc and plane ids, so that
# we can select the screen to capture in multi monitor setups.
# Currently it uses defaults, which might not be the monitor you want.
#
# It looks like crtc ids can be found using the debugfs (which is already enabled in my ubuntu install). The location /sys/kernel/debug/dri/0/i915_display_info contains details of the crtcs, along with their id and resolutions. 

# Resources
# https://gist.github.com/edrex/82f307c1b35368952849c01a52366769
# https://gist.github.com/Brainiarc7/7b6049aac3145927ae1cfeafc8f682c1
# https://ffmpeg.org/ffmpeg-devices.html#kmsgrab

usage() {
    cat <<EOF
usage: $(basename $0) <outputfilename>
EOF
}

select_crtc() {
    SCREEN_OPTIONS=($(sudo cat /sys/kernel/debug/dri/0/i915_display_info | grep CRTC | grep size | awk '/CRTC/{print $2 $6}'))
    PS3="Please choose the screen to record "
    select option in "${SCREEN_OPTIONS[@]}"; do
        if [ 1 -le "$REPLY" ] && [ "$REPLY" -le $((${#SCREEN_OPTIONS[@]})) ]; then
            # echo "You selected $option which is option $REPLY"
            local crtc=`echo $option | sed -n "s/\(\S*\):.*$/\1/p"`
            echo $crtc
            break;
        else
            echo "Incorrect selection. Select a number 1-${#SCREEN_OPTIONS[@]}"
        fi
    done
}

if [ $# -eq 0 ]; then
    usage
    exit 1
fi

output_file="$1"

crtc_id=$(select_crtc)

sudo ffmpeg \
     -crtc_id ${crtc_id} \
     -framerate 30 \
     -f kmsgrab \
     -i - \
     -vaapi_device /dev/dri/renderD128 \
     -filter:v hwmap,scale_vaapi=w=1920:h=1080:format=nv12 \
     -c:v h264_vaapi \
     -profile:v constrained_baseline \
     -level:v 3.1 \
     -b:v 20000k \
     "${output_file}"
