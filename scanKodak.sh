#!/bin/bash

# Scans from a hard-coded scanner to a pdf in the current directory

TMPFILE=$(mktemp)

gs='-type Grayscale'
qual='50%'
dpi='150'

# Get options
while getopts ":f:cqr:" Option
do
  case $Option in
    f ) FILE=$OPTARG;;
    c ) gs='';;
    q ) qual='85%';;
    r ) dpi=$OPTARG;;
  esac
done


# Check if file is set
if [[ ! "$FILE" ]]
then
	FILE="$(date +"%F %H%M%S").pdf"
fi

echo Will output to file "$FILE"

#Scan pages and store .tiffs
#'-d avision' hardcodes the kodak scanner. It is not necessary if you have only one scanner connected, however 'scanimage -L' shows sometimes other devices like webcams as scanners (and picks the first one) If you're using a different device, remove or change this argument.
echo Starting scan...
scanimage -d avision --format tiff -p --batch=$TMPFILE%04d.tiff --source 'ADF Duplex' --resolution $dpi

#use imagemagick to compress all tiffs and glue them to a single pdf
echo Glueing pages...
convert $TMPFILE*.tiff $gs -quality $qual -density "$dpi"x"$dpi" -compress jpeg $TMPFILE.all.pdf

#Output to given file
if [[ ! -f $FILE ]]
then
	#File does not exist. This is easy
	echo Creating new PDF $FILE and fixing title.
	#updating the title because "tmp.rvvk8ozNjn.pdf" just doesn't look good in the title bar, also moving the file away from tmp
	exiftool -q $TMPFILE.all.pdf -title="${FILE}" -author=$USER -o "$FILE"
else
	#File exists. cat'ing files together
	echo Appending to existing PDF $FILE
	mv "$FILE" "$FILE.tmp.pdf"
	qpdf "$FILE.tmp.pdf" --pages "$FILE.tmp.pdf" $TMPFILE.all.pdf -- "$FILE"
	rm "$FILE.tmp.pdf"
fi


rm $TMPFILE*
