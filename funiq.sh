#!/bin/sh
#
# (C) David Lambert, 2008-10-01
# Fuzzy uniq (or Parsing Connect:Direct stats part 3)
# http://cdunix.blogspot.com/2008/10/fuzzy-uniq-or-parsing-connectdirect.html
#
# Get percentage of similarity from command line option, or 85 for default
#

# Percentage of similarity
if [ -n "$1" ]; then
	SIM=$1
else
	SIM=85
fi

awk 'BEGIN {CURRPAIRS=0;PAIRMATCHES=0;PREVPAIRS=0}
{
	# load array of character pairs for current comparison string
	for (i=1;i<length($0);i++) {
		CURR[i]=substr($0,i,2)
	}

	# remove character pairs that contain spaces
	for (SUBC in CURR) {
		if ( index(CURR[SUBC]," ") ) {
		delete CURR[SUBC]
		}
	}

	# count the number of character pairs in comparison string,
	# and count matches compared to previous comparison string
	CURRPAIRS=0
	PAIRMATCHES=0
	for (SUBC in CURR) {
		CURRPAIRS++
		for (SUBP in PREV) {
			if (CURR[SUBC]==PREV[SUBP]) {
			PAIRMATCHES++
			# only count matches once
			delete PREV[SUBP]
			}
		}
	}

	# remove empty lines from consideration by skipping to next line
	if (CURRPAIRS==0) next

	# compute similarity
	SIM=200*PAIRMATCHES/(CURRPAIRS+PREVPAIRS)

	# display output if not similar
	if (REQSIM >= SIM) print $0

	# move array of character pairs to store as previous string
	for (SUB in PREV) delete PREV[SUB]
	for (SUB in CURR) PREV[SUB]=CURR[SUB]
	for (SUB in CURR) delete CURR[SUB]
	PREVPAIRS=CURRPAIRS
}' REQSIM=$SIM $@
