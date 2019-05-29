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

# Tell the webcam we live in a 50hz power area (removes flicker)
v4l2-ctl --device=${webcam} -c power_line_frequency=1 


#
# convert on the fly.
#
# ffmpeg \
#     -f v4l2 \
#     -video_size 640x480 \
#     -framerate 30 \
#     -input_format yuyv422 \
#     -i ${webcam} \
#     -f pulse \
#     -channels 2 \
#     -i ${microphone} \
#     -c h264 \
#     -acodec aac -ab 128k \
#     "${output_file}".mp4

#
# Speed version - no conversion, just capture raw input
#
# WARNING: This will produce massive files!
ffmpeg \
    -f v4l2 \
    -video_size 640x480 \
    -framerate 30 \
    -input_format yuyv422 \
    -i ${webcam} \
    -f pulse \
    -channels 2 \
    -i ${microphone} \
    -c copy \
    -acodec copy \
    "${output_file}".mkv
