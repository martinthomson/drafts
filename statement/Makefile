TOP := ..
include ${TOP}/Makefile

ifeq "$(shell uname -s 2>/dev/null)" "Darwin"
sed_i := sed -i ''
else
sed_i := sed -i
endif

txt::
	[ -f ${BASE}.txt ] && $(sed_i) -e 's/^   \.//' ${BASE}.txt || true
submit::
	$(sed_i) -e 's/^   \.//' ${BASE_NEXT}.txt
