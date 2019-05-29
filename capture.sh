#!/bin/bash

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

select_webcam() {
    CAM_OPTIONS=($(v4l2-ctl --list-devices | grep video ))
    PS3="Please choose the webcam to use "
    select option in "${CAM_OPTIONS[@]}"; do
        if [ 1 -le "$REPLY" ] && [ "$REPLY" -le $((${#CAM_OPTIONS[@]})) ]; then
            echo $option
            # echo "You selected $option which is option $REPLY"
            #local crtc=`echo $option | sed -n "s/\(\S*\):.*$/\1/p"`
            #echo $crtc
            break;
        else
            echo "Incorrect selection. Select a number 1-${#CAM_OPTIONS[@]}"
        fi
    done
}

select_microphone() {
    MIC_OPTIONS=($(pactl list | grep -A2 'Source #' | grep alsa_input | grep 'Name: ' | cut -d" " -f2))
    PS3="Please choose the microphone to use "
    select option in "${MIC_OPTIONS[@]}"; do
        if [ 1 -le "$REPLY" ] && [ "$REPLY" -le $((${#MIC_OPTIONS[@]})) ]; then
            echo $option
            # echo "You selected $option which is option $REPLY"
            #local crtc=`echo $option | sed -n "s/\(\S*\):.*$/\1/p"`
            #echo $crtc
            break;
        else
            echo "Incorrect selection. Select a number 1-${#MIC_OPTIONS[@]}"
        fi
    done
}

capture_desktop() {
    sudo ffmpeg -loglevel quiet -hide_banner -nostats \
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
         "${output_file}"-desktop.mp4 &
}

capture_webcam() {
    ffmpeg -loglevel quiet -hide_banner -nostats \
        -f v4l2 \
        -video_size 640x480 \
        -framerate 30 \
        -input_format yuyv422 \
        -i $1 \
        -f pulse \
        -channels 2 \
        -i $2 \
        -c h264 \
        -acodec aac -ab 128k \
        "$3"-webcam.mkv &
}

if [ $# -eq 0 ]; then
    usage
    exit 1
fi

output_file="$1"

crtc_id=$(select_crtc)
webcam=$(select_webcam)
microphone=$(select_microphone)

# Tell the webcam we live in a 50hz power area (removes flicker)
v4l2-ctl --device=${webcam} -c power_line_frequency=1

# Wait for user to be ready.
read -p "Ready. Press any key to start recording..." -n1 -s

capture_webcam ${webcam} ${microphone} ${output_file}; capture_desktop ${crtc_id} ${output_file};

#Wait for user to finish
read -p "Press any key to stop recording." -s
sudo killall -15 ffmpeg

