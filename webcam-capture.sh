#!/bin/bash

#
# A script to capture video from a webcam, hardware accellerated.
#

usage() {
    cat <<EOF
usage: $(basename $0) <outputfilename>
EOF
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

if [ $# -eq 0 ]; then
    usage
    exit 1
fi

output_file="$1"

webcam=$(select_webcam)
microphone=$(select_microphone)

ffmpeg \
    -threads:v 2 -threads:a 8 -filter_threads 2 \
    -f v4l2 \
    -video_size 640x480 \
    -framerate 30 \
    -i ${webcam} \
    -thread_queue_size 1024 \
    -f pulse \
    -channels 1 \
    -i ${microphone} \
    -ac 1 \
    "${output_file}"

# sudo ffmpeg \
#     -f v4l2 \
#     -video_size 640x480 \
#     -framerate 30 \
#     -i ${webcam} \
#     -f pulse \
#     -channels 1 \
#     -i "${microphone}" \
#     -vaapi_device /dev/dri/renderD128 \
#     -filter:v hwmap,scale_vaapi=w=640:h=480:format=nv12 \
#     -c:v h264_vaapi \
#     -profile:v constrained_baseline \
#     -level:v 3.1 \
#     -b:v 20000k \
#     "${output_file}"
