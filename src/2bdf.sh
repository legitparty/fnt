#!/bin/sh
# See LICENSE for legal matters.

# Your font directory may contain a Settings
# file that can override all the defaults
# below.

set -e

if test -z $1
then
	echo "usage: 2bdf.sh FONTDIR" 1>&2
	exit 1
fi

FONT=$1

FOUNDRY="mpu"      # Foundry name
NAME="yourfont"    # Font name
WEIGHT="medium"    # bold, demibold, medium, or regular
SLANT="r"          # i, o, or r 
SETWIDTH="normal"  # normal, or semicondensed
SPACING="c"        # c, m or p
BASELINE=2         # y position of the baseline

test -e $FONT/Settings && . $FONT/Settings

D=${FONT##*/}
W=${D%x*}
H=${D#*x}

cat << EOI
STARTFONT 2.1
FONT -$FOUNDRY-$NAME-$WEIGHT-$SLANT-$SETWIDTH--$H-$(($H * 10))-75-75-$SPACING-$(($W * 10))-iso10646-1
SIZE $H 75 75
FONTBOUNDINGBOX $W $H 0 -$BASELINE

STARTPROPERTIES 20
FONTNAME_REGISTRY ""
FOUNDRY "$FOUNDRY"
FAMILY_NAME "$NAME"
WEIGHT_NAME "$WEIGHT"
SLANT "$SLANT"
SETWIDTH_NAME "$SETWIDTH"
ADD_STYLE_NAME ""
PIXEL_SIZE $H
POINT_SIZE $(($H * 10))
RESOLUTION_X 75
RESOLUTION_Y 75
SPACING "$SPACING"
AVERAGE_WIDTH $(($W * 10))
CHARSET_REGISTRY "ISO10646"
CHARSET_ENCODING "1"
DESTINATION 1
FONT_ASCENT  $(($H - $BASELINE))
FONT_DESCENT $BASELINE
FONT_VERSION "1"
COPYRIGHT ""
ENDPROPERTIES

CHARS $(ls $FONT | grep -v "^Settings$" | wc -l)
EOI

for path in $(cd $FONT && ls -1)
do
	if printf "%s" "${path}" | grep -q '^U+'
	then
		G="$(printf "%s" "${path}" | cut -b3-)"
	elif grep -q "^${path}," "$(dirname "${0}")"/entities.csv
	then
		G="$(grep "^${path}," "$(dirname "${0}")"/entities.csv | cut -d, -f2)"
	else
		continue
	fi

	CODE=$(printf "%d" "0x${G#*U+}")
	echo STARTCHAR "U+${G}"
	echo ENCODING $CODE
	echo SWIDTH 960 0
	echo DWIDTH $W 0
	echo BBX $W $H 0 -$BASELINE
	echo BITMAP

	awk "
	{
		hex = 0;
		split(\$0, chars, \"\")
		for (i=1; i<=8; i++)
			if (chars[i] == \"x\")
				hex = hex * 2 + 1;
			else
				hex = hex * 2;
		printf \"%02X\\n\", hex
	}
	" "${FONT}/${path}"

	echo ENDCHAR
done

echo ENDFONT
