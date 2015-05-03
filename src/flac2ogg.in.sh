#!/bin/sh
# Recursively find FLAC files starting in given directory 
# and convert them to ogg vorbis files
ver=2.0

#\\ifdef WDMSG 
. @libdir@/libsh
#\\define MSG_TOOL_HELP_STR "d_msg Help"
#\\else
appname=${0##*/}
#\\define MSG_TOOL_HELP_STR cat
#\\endif
MAX_ARGS=2

umlaut_cleaner() 
# remove umlauts for FAT file systems
{
    echo "$1" | sed -e 's|ö|o|g' -e 's|ü|u|g' -e 's|ä|a|g'
}

fatfix()
# clean not allowed chars from input for sane file names
# on fat file systems
{
    umlaut_cleaner "$1" | sed -e 's|:||g' 
}


stub_main()
# core function
{
    local FLACFILE="$1"
    shift
    
    # Grab the id3 tags from the FLAC file
    ARTIST=$(metaflac "$FLACFILE" --show-tag=ARTIST | sed s/.*=//g)
    TITLE=$(metaflac "$FLACFILE" --show-tag=TITLE | sed s/.*=//g)
    ALBUM=$(metaflac "$FLACFILE" --show-tag=ALBUM | sed s/.*=//g)
    GENRE=$(metaflac "$FLACFILE" --show-tag=GENRE | sed s/.*=//g)
    TRACKNUMBER=$(metaflac "$FLACFILE" --show-tag=TRACKNUMBER | sed s/.*=//g)
    DATE=$(metaflac "$FLACFILE" --show-tag=DATE | sed s/.*=//g)
    COVERART=$(metaflac --export-picture-to=- "$FLACFILE" | base64 --wrap=0 -)
    # A little shell globbing to get the filename
    # (everything after the rightmost "/")
    FILENAME=${FLACFILE##*/}
      # Build the output path and rename the file
    OGGFILE=$(echo "$DESTINATION_DIR/$ARTIST/$ALBUM/$FILENAME" | sed s/\.flac$/.ogg/g)
    if [ $fatsave ] ; then
	OGGFILE=$(fatfix "$OGGFILE")
    fi
    # Convert to OGG at 320kbps (use -q6 for 192kbps)
    oggenc -q9 --discard-comments -a "$ARTIST" -t "$TITLE" -l "$ALBUM" -G "$GENRE" -N "$TRACKNUMBER" -d "$DATE" -o "$OGGFILE" "$FLACFILE"
    if [ $deprecovertag ] ; then
	vorbiscomment -a -c "COVERTAG=$COVERTAG" "$OGGFILE"
    else
	vorbiscomment -a  -t "METADATA_BLOCK_PICTURE=$COVERART" "$OGGFILE"
    fi
}

old_main()
# old main without using parallel
{
    find "$TARGET_DIR" -name \*.flac  | while read FLACFILE
    do
        stub_main "$FLACFILE"
    done 
    
    if [ $coverd ] ; then
        printf "%s" "$COVERART" > "${OGGFILE##*/}"/cover.jpg
    fi
}

main()
{
    find "$TARGET_DIR" -name \*.flac | while read FLACFILE
    do
        echo "flac2ogg --stub-main \"$DESTINATION_DIR\" \"$FLACFILE\""
    done | parallel
}

print_help() {
@MSG_TOOL_HELP_STR@ <<_HELP_MSG
  $appname $ver - usage:
      $appname [options] <target_dir> <destination_dir>
options
  --fatfix           use fat save filenames
  --coverd           save cover.jpg file in album dir
  --depre-covertag   use depreacted COVERTAG comment in ogg file
_HELP_MSG
}
OPTS=h
LONG_OPTS=coverd,depre-covertag,fat-save,help,old-main,stub-main
P_OPTS=$(getopt -o $OPTS -l $LONG_OPTS -n $appname -- "${@}" )
eval set -- "$P_OPTS"
while [ ! $# = 0 ] ; do
    case "$1" in
	--stub-main|--convert) shift; stub_main=t;;
	--fat-save) fatsave=True; shift ;;
	--coverd) coverd=True ; shift ;;
	--depre-covertag) deprecovertag=True; shift ;;
        --old-main) old_main=t;shift;;
	-h|--help) print_help; exit ;;
	--) shift ; break ;;	
    esac
done
if [ $# -ge $MAX_ARGS ] || [ $stub_main ] ; then
    if [ $stub_main ] ; then
        DESTINATION_DIR=$1
        shift
        stub_main "$@"
    else
        TARGET_DIR=$1
        DESTINATION_DIR=$2
        shift 2
        if [ $old_main ] ; then
            old_main
        else
            main
        fi
       
    fi
else
#\\ifdef WDMSG
    d_msg ! Input "no or to less arguments given"
#\\else
    echo "no or to less arguments given" >&2
#\\endif
fi
