#!/bin/bash

set -e

OUTPUT=$(cd $OUTPUT && pwd);
BUILD_DIR=$(mktemp -d -t ffmpeg);
cd $BUILD_DIR;

URL=https://downloads.sourceforge.net/project/ffmpeg-ios/ffmpeg-ios-master.tar.bz2

for i in 1 2 3 4 5; do
	echo "** Downloading ffmpeg-ios (attempt $i) ..."
	if curl -fL --retry 3 --retry-delay 5 --connect-timeout 30 -o ffmpeg-ios-master.tar.bz2 "$URL" \
		&& bunzip2 -t ffmpeg-ios-master.tar.bz2; then
		break
	fi
	echo "** Download corrupted, retrying ...";
	rm -f ffmpeg-ios-master.tar.bz2;
	sleep 10;
done

[[ -f ffmpeg-ios-master.tar.bz2 ]] || { echo "** ERROR: failed to download ffmpeg-ios"; exit 1; }
bunzip2 -kf ffmpeg-ios-master.tar.bz2
tar xf ffmpeg-ios-master.tar
[[ -d FFmpeg-iOS ]] || { echo "** ERROR: FFmpeg-iOS not found in archive"; exit 1; }

cp -av FFmpeg-iOS/include/* $OUTPUT/include;
cp -av FFmpeg-iOS/lib/* $OUTPUT/iphone;

[[ -f "$OUTPUT/include/libavcodec/version.h" ]] || { echo "** ERROR: libavcodec/version.h missing"; exit 1; }

[[ -d "$BUILD_DIR" ]] && rm -rf $BUILD_DIR;
