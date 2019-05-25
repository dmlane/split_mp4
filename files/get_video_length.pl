#!/usr/bin/env perl
# File:           get_video_length.pl
# Author:         Dave Lane
# Description:
#    Print the length of the mp4 file given as 1st parameter. Output
#    us in HH:MM:SS.MS format.

use strict;
use MP4::Info;
my ($fn)=@ARGV;
my $info=get_mp4info($fn) or die "Cannot get length of video from '$fn': $!\n";
my $vhours=int($info->{MM}/60);
my $vmins=int($info->{MM}%60);
printf("%02d:%02d:%02d.%003d",$vhours,$vmins,$info->{SS},$info->{MS});
