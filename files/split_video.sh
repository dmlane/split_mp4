#!/bin/bash

#------------------------
#	$1 - Name of input file
#
#------------------------

function usage {
	echo "$0 -i <input_file> -f start_time -t end_time output_file"
	echo "    Where times must be in format HH:MM:SS.nnn"
	exit 1
	}
function fail {
	echo "$*"
	echo "     aborting!"
	exit 2
	}
function test_time {
	[[ ${!1} =~ ^[0-9]{2}:[0-9]{2}:[0-9]{2}\.[0-9]{3}$ ]] ||\
		fail "$1 not in format HH:MM:SS.nnn (${!1})"
	}

function get_key_frames {
	local mp4_file=$1
	local frame_file=$2
    test -s $frame_file || rm -f $frame_file
    if [ $mp4_file -ot $frame_file ] ; then
		echo "Using cached frame file for $mp4_file"
		return
	fi
	echo "Fetching key frames from $mp4_file"
    ffprobe \
        -skip_frame nokey -select_streams v  -show_frames -show_entries frame=pkt_pts_time \
        -v quiet -of csv  $mp4_file >ffprobe.txt || fail "ffprobe failed"
    sed -n 's/^frame,\(.*\.[0-9][0-9][0-9]\).*$/\1/p' ffprobe.txt >$frame_file ||\
		fail "sed on ffprobe.txt failed"
	rm ffprobe.txt 
}

while getopts "i:f:t:" c
do
	case $c in
		i)	input_file=$OPTARG;;
		f)	start_time=$OPTARG
			test_time start_time;;
		t)	end_time=$OPTARG
			test_time end_time;;
		*)	usage;;
	esac
done
shift $((OPTIND-1))
test $# -lt 1 && fail "No output file provided"
output_file=$1

test -z "$input_file" && usage
test -z "$output_file" && usage
test -z "$start_time" && usage
test -z "$end_time" && usage

test -f $input_file ||\
	fail "'$input_file' does not exist"
if [ -f $output_file ] ; then
	echo "Warning: overwriting output file $output_file"
	rm -f $output_file
fi

#---------------------------
video_length="$(get_video_length.pl $input_file)"
test -z "$video_length" && fail "get_video_length.pl failed for $input_file"
echo "Length of $input_file is $video_length"

if [ $start_time == "00:00:00.000" ] ; then
	if [ $end_time == $video_length ] ; then
		# We want the whole file, so we can just copy it
		echo "We want the whole file, so just copying"
		cp $input_file $output_file ||
			fail "Unable to copy full file from $input_file to $output_file"
		exit 0
	else
		key_frame_secs=0.000
	fi
else
	# Make sure we use key-frames for the start frame
	frame_secs=$(awk 'BEGIN{FS=":"}{printf "%.3f\n" ,((($1*60)+$2)*60)+$3}' <<<$start_time)
	frame_file=${input_file##*/}.frames
    get_key_frames $input_file $frame_file
    key_frame_secs=$(awk "{if (\$1 <= $frame_secs)v=\$1}END {print v}" $frame_file)
	test "$key_frame_secs" == "$frame_secs" ||
		echo "Adjusting start time from $frame_secs to $key_frame_secs to be on a key frame"
fi

tmp_file=${output_file/.mp4/_temp.mp4}
test -f $tmp_file && rm -f $tmp_file
echo "Processing $mp4_file (-ss=${key_frame_secs} -to=$end_time)"
ffmpeg -loglevel warning -y -i ${input_file} -ss ${key_frame_secs} -to $end_time \
	-c copy $tmp_file
if [ $? -ne 0 ] ; then
	rm -f $tmp_file
	fail "ffmpeg failed processing $input_file -ss ${key_frame_secs} -to $end_time"
fi

mv $tmp_file $output_file
if [ $? -ne 0 ] ; then
	ls -l $tmp_file
	rm -f $tmp_file
	fail "Could not move $tmp_file to $output_file"
fi
	
	
	



