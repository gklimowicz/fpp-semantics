ALL_STD =	INCITS+ISO+IEC+9899-6.10-1999-from-all.org \
	INCITS+ISO+IEC+9899-6.10-2011-from-all.org \
	INCITS+ISO+IEC+9899-6.10-2018-from-all.org

all:	requirements.txt ${ALL_STD}

requirements.txt:	requirements.org
	pandoc -f org -t plain requirements.org >"$@"

# 1999: Delete all changes that are strictly after 1999.
INCITS+ISO+IEC+9899-6.10-1999-from-all.org: INCITS+ISO+IEC+9899-6.10-all.org Makefile
	sed -e 's/{{1999[0-9|]*=\([^}]*\)}}/\1/g' \
	    -e 's/{{201[18][0-9|]*=[^}]*}}//g' \
	    -e '/^{{201[18][0-9|]*=$$/,/^}}/d' \
	    -e '/^{{2024[0-9|]*=$$/,/^}}/d' \
	    -e '/^{{1999[0-9|]*=$$/d' -e '/^}}/d' \
	    <INCITS+ISO+IEC+9899-6.10-all.org \
	    >"$@"

# 2011: Delete strictly 1999 changes and changes strictly after 2011.
INCITS+ISO+IEC+9899-6.10-2011-from-all.org: INCITS+ISO+IEC+9899-6.10-all.org Makefile
	sed -e 's/{{1999=\([^}]*\)}}//g' \
	    -e 's/{{[0-9|]*2011[0-9|]*=\([^}]*\)}}/\1/g' \
	    -e 's/{{2018[0-9|]*=[^}]*}}//g' \
	    -e '/^{{1999=$$/,/^}}/d' \
	    -e '/^{{2018[0-9|]*=$$/,/^}}/d' \
	    -e '/^{{2024[0-9|]*=$$/,/^}}/d' \
	    -e '/^{{[0-9|]*2011[0-9|]*=$$/d' -e '/^}}/d' \
	    <INCITS+ISO+IEC+9899-6.10-all.org \
	    >"$@"

# 2018: Delete strictly 1999, 2011 changes and changes strictly after 2018.
INCITS+ISO+IEC+9899-6.10-2018-from-all.org: INCITS+ISO+IEC+9899-6.10-all.org Makefile
	sed -e 's/{{1999=\([^}]*\)}}//g' \
	    -e 's/{{[0-9|]*2011=\([^}]*\)}}//g' \
	    -e 's/{{[0-9|]*2018[0-9|]*=\([^}]*\)}}/\1/g' \
	    -e 's/{{2024[0-9|]*=[^}]*}}//g' \
	    -e '/^{{1999=$$/,/^}}/d' \
	    -e '/^{{[0-9|]*2011=$$/,/^}}/d' \
	    -e '/^{{2024[0-9|]*=$$/,/^}}/d' \
	    -e '/^{{[0-9|]*2018[0-9|]*=$$/d' -e '/^}}/d' \
	    <INCITS+ISO+IEC+9899-6.10-all.org \
	    >"$@"

clean:
	rm -f .DS_Store *.aux *.fdb_latexmk *.fls *.log *.out *.tex ${ALL_STD}
