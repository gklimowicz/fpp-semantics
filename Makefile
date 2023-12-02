E=fortran-examples

all: stats.csv

stats.csv:	fortran-examples/all-fortran-files.txt Makefile\
		bin/fpp-stats bin/fpp-stats.awk
	(HERE=`pwd`; \
	 export LC_ALL=C; \
	 $${HERE}/bin/fpp-stats -H; \
	 builtin cd ${E} && \
	 cat all-fortran-files.txt \
	 | tr '\n' '\0' \
	 | xargs -0 $${HERE}/bin/fpp-stats) >>"$@.$$$$" \
	 && mv "$@.$$$$" "$@"
	wc -l "$@"

FORCE:
