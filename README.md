# split_mp4
Split an MP4 usinf ffmpeg from Docker( ensuring we use Key-frames for the start position)

Usage:

docker run -v /tmp:/tmp/workdir davelux/split_mp4 -i INPUT_FILE -f START_TIME -t END_TIME Output_File

It's useful to map the volume /tmp/workdir so that key_frames can be cached for reuse. Other volumes
are probably needed for the input and output file - I map it to /tmp/input and /tmp/output
