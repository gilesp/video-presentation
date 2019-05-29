#!/bin/bash

#
# A script to combine two videos and a static template image into a single video.
#
# Intended use is for videos of presentations with slides. Capture a
# screen recording of the slides, and a video of the speaker, then
# combine them with the template to produce a branded, cohesive video
# for sharing.
#
# Assumed coordinates on template image:
# Large area (for presentation video)
#  Width: 1280, Height: 720
#  TOP-LEFT: 30, 30
#  TOP-RIGHT: 1310, 30
#  BOTTOM-LEFT: 30, 750
#  BOTTOM-RIGHT: 1310, 750
#
# Small area (for speaker video)
#  Width: 566, Height: 318
#  TOP-LEFT: 1335, 32
#  TOP-RIGHT: 1901, 32
#  BOTTOM-LEFT: 1335, 350
#  BOTTOM-RIGHT: 1901, 350 

usage() {
    cat <<EOF
usage: $(basename $0) --template <templatefile> --speaker <speaker_video> --presentation <presentation_video> <outputfilename>

  -p|--presentation Video file of presentation slides
  -s|--speaker      Video of speaker
  -t|--template     Filename of template to use
EOF
}

# Argument parsing taken from https://stackoverflow.com/a/14203146
POSITIONAL=()
presentation_video="presentation.mp4"
speaker_video="speaker.mp4"
template_image="template.png"

while [ "$#" -gt 0 ]; do
  case "$1" in
      -p|--presentation)
          presentation_video="$2"; shift 2;;
      -s|--speaker)
          speaker_video="$2"; shift 2;;
      -t|--template)
          template_image="$2"; shift 2;;
      *) # nospecific option
          POSITIONAL+=("$1") # save into array
          shift
          ;;
  esac
done
set -- "${POSITIONAL[@]}" # restore positional parameters

if [[ ${#POSITIONAL[@]} != 1 ]]; then
    usage
    exit 1
fi

output_file="$1"

#1 Scale presentation video to 1280x720
#2 Scale speaker video to 566x318

ffmpeg -y \
       -loop 1 \
       -i "${template_image}" \
       -i "${presentation_video}" \
       -i "${speaker_video}" \
       -filter_complex "[1]scale=1280x720[slides]; [2]scale=566x318[speaker]; [0][slides]overlay=x=30:y=30:shortest=1[main]; [main][speaker]overlay=x=1335:y=30:shortest=1" \
       ${output_file}
