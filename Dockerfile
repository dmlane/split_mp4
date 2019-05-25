from jrottenberg/ffmpeg
RUN apt-get update && apt-get install -y \ 
	libmp4-info-perl
COPY files/* /usr/local/bin/
ENTRYPOINT ["/usr/local/bin/split_video.sh"]
CMD [""]
