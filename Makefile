# Makefile for Fortran preprocessor statistincs.
# Requires 'gmake' as we use the .ONESHELL target to simplify
# the wanky parallel script that computes the statistics.
# (It's getting to the point where this should probably
# be pulled into a separate bash script.)

E=fortran-examples

.ONESHELL:
SHELL=/bin/bash

all: stats.csv

# Compute the stats in parallel and concatenate results.
# This is awkward, but cuts the time to generate them down dramatically.
# Note that since all-fortran-files.txt is sorted, the stats.csv
# file will be as well, without having to explicitly sort it.

# Calculation of N_SPLIT adds 1 to avoid a tiny file at the end.

stats.csv:	fortran-examples/all-fortran-files.txt Makefile \
		bin/fpp-stats bin/fpp-stats.awk
	export LC_ALL=C
	N=$$(nproc)
	HERE=`pwd`
	SPLIT_TMP="$${HERE}/aff-split.$$$$"
	STATS_TMP="$${HERE}/$@.$$$$"
	cd ${E}
	N_SPLIT=$$(($$(wc -l <all-fortran-files.txt | tr -d ' ') / $$N + 1))
	split -d -l $$N_SPLIT all-fortran-files.txt "$$SPLIT_TMP."
	trap 'killall -q xargs; killall -q bash' HUP INT QUIT KILL TERM
	trap 'rm -f "$$SPLIT_TMP."* "$$STATS_TMP".*' EXIT
	for F in "$$SPLIT_TMP".*; do \
	      SUFFIX="$${F/*.*.}"
	      tr '\n' '\0' <"$$F"\
	      | xargs -0 $${HERE}/bin/fpp-stats >"$$STATS_TMP.$$SUFFIX"& \
	done
	wait
	cd $${HERE}
	(bin/fpp-stats -H; cat "$$STATS_TMP".*) >"$@"
	wc -l "$@"

FORCE:
