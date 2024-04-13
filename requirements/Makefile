requirements.txt:	requirements.org Makefile
	pandoc -f org -t plain requirements.org >"$@"

INCITS+ISO+IEC+9899-6.10-1999-from-all.org: INCITS+ISO+IEC+9899-6.10-all.org
	sed -e 's/{{2011- \([^}]*\)}}/\1/g' \
	       -e 's/ {{2011+ [^}]*}}\([ .]\)/\1/g' \
	       -e 's/{{2011+ [^}]*}}//g' \
		<INCITS+ISO+IEC+9899-6.10-all.org \
	| sed -e '/{{2011+$$/,/^}}/d' \
	      -e '/{{2011-$$/d' -e '/^}}/d'  >"$@"
