#!/bin/bash

set -e

OUTPUT=$(cd $OUTPUT && pwd);
BUILD_DIR=$(mktemp -d -t ffmpeg);
cd $BUILD_DIR;

URL=https://downloads.sourceforge.net/project/ffmpeg-ios/ffmpeg-ios-master.tar.bz2
EXPECTED_SIZE=85838344

# SourceForge transfers get cut mid-stream on CI; use resumable download loop.
for i in $(seq 1 25); do
	echo "** Downloading ffmpeg-ios (attempt $i, resumable) ..."
	curl -fL -C - --retry 3 --retry-delay 5 --connect-timeout 30 -o ffmpeg-ios-master.tar.bz2 "$URL" || true
	SZ=$(stat -f%z ffmpeg-ios-master.tar.bz2 2>/dev/null || echo 0)
	echo "** got $SZ / $EXPECTED_SIZE bytes"
	if [[ "$SZ" -ge "$EXPECTED_SIZE" ]] && bunzip2 -t ffmpeg-ios-master.tar.bz2; then
		echo "** Download complete and valid."
		break
	fi
	sleep 5
done

[[ -f ffmpeg-ios-master.tar.bz2 ]] || { echo "** ERROR: failed to download ffmpeg-ios"; exit 1; }
bunzip2 -t ffmpeg-ios-master.tar.bz2 || { echo "** ERROR: archive corrupted after all attempts"; exit 1; }
bunzip2 -kf ffmpeg-ios-master.tar.bz2
tar xf ffmpeg-ios-master.tar
[[ -d FFmpeg-iOS ]] || { echo "** ERROR: FFmpeg-iOS not found in archive"; exit 1; }

cp -av FFmpeg-iOS/include/* $OUTPUT/include;
cp -av FFmpeg-iOS/lib/* $OUTPUT/iphone;

[[ -f "$OUTPUT/include/libavcodec/version.h" ]] || { echo "** ERROR: libavcodec/version.h missing"; exit 1; }

[[ -d "$BUILD_DIR" ]] && rm -rf $BUILD_DIR;
