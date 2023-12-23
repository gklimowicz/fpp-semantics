E=fortran-examples

all: stats.csv

# Compute the stats in parallel and concatenate results.
# This is awkward, but cuts the time to generate them down dramatically.
# Note that since all-fortran-files.txt is sorted, the stats.csv
# file will be as well, without having to explicitly sort it.

# N is the number of processes to split the work over.
N=6

stats.csv:	fortran-examples/all-fortran-files.txt Makefile \
		bin/fpp-stats bin/fpp-stats.awk
	HERE=`pwd`; \
	export LC_ALL=C; \
	builtin cd ${E}; \
	N_SPLIT=$$(($$(wc -l <all-fortran-files.txt | tr -d ' ') / $N)); \
	split -d -l $$N_SPLIT all-fortran-files.txt "$${HERE}/aff-split.$$$$."; \
	for F in $${HERE}/aff-split.$$$$.*; do \
	      SUFFIX="$${F/*.*.}"; \
	      tr '\n' '\0' <"$$F"\
	      | xargs -0 $${HERE}/bin/fpp-stats >"$${HERE}/$@.$$$$.$$SUFFIX"& \
	done; \
	wait; \
	cd $${HERE}; \
	(bin/fpp-stats -H; cat "$@.$$$$".*; rm "$@.$$$$".*) >"$@"
	wc -l "$@"

FORCE:
