E=fortran-examples

all: all-stats.csv

all-stats.csv:	fortran-examples/all-fortran-files Makefile bin/fpp-stats bin/fpp-stats.awk
	export HERE=`pwd`; \
	$$HERE/bin/fpp-stats -H >"$@"; \
	(builtin cd ${E} && \
	 export LC_ALL=C; \
	 cat all-fortran-files \
	 | tr '\n' '\0' \
	 | xargs -0 $$HERE/bin/fpp-stats) \
	>>"$@"
	wc -l "$@"

FORCE:
