ifeq "$(shell uname -o 2>/dev/null)" "Cygwin"
    CYGPATH := cygpath --windows
else
    CYGPATH := echo
endif
ifeq "$(shell uname -s 2>/dev/null)" "Darwin"
    sed_i := sed -i ''
else
    sed_i := sed -i
endif

BASE := $(lastword $(basename $(wildcard draft-*.xml)))
XML := ${BASE}.xml
DTD := rfc2629.dtd
XSLT := rfc2629.xslt

# SAXON := java -jar '$(subst \,\\,$(shell ${CYGPATH} ${TOP}/saxon8.jar))'
VALIDATE := ${TOP}/validate
SAXON := java -jar '$(shell ${CYGPATH} ${TOP}/saxon8.jar)'
XML2RFC ?= ${TOP}/webxml2rfc.sh
XSLT_HOME := ${TOP}/rfc2629xslt
HTML_XSLT := false
IDNITS := ${TOP}/idnits/idnits

REV_CURRENT := $(shell git tag | grep "${BASE}" | tail -1 | sed -e"s/.*-//")
ifeq "${REV_CURRENT}" ""
REV_NEXT ?= 00
else
REV_NEXT ?= $(shell printf "%.2d" $$((1${REV_CURRENT}-99)))
endif
BASE_NEXT := ${BASE}-${REV_NEXT}

.PHONY: default all extra nits validate clean submit recurse tag
ifeq (,${TOP})
TOP := .
default: recurse
clean: rclean
else
default: txt
clean: cleandir
endif
extra: default html pdf xhtml svg nr unpg
all: extra nits validate

.PHONY: txt html xhtml pdf svg nr unpg
default: skipdir
ifeq (,$(shell grep 'date' ${BASE}.xml | grep 'year="$(shell date +%Y)"' 2>&1))
txt:: skipdir
html:: skipdir
xhtml:: skipdir
pdf:: skipdir
svg:: skipdir
nr:: skipdir
unpg:: skipdir
else
txt:: ${BASE}.txt
html:: ${BASE}.html
xhtml:: ${BASE}.xhtml
pdf:: ${BASE}.pdf
svg:: ${BASE}.svg
nr:: ${BASE}.nr
unpg:: ${BASE}.unpg
endif

.TRANSIENT: tmp.fo ${BASE}.svg~

ifeq "${HTML_XSLT}" "false"
extra_css := ${TOP}/lib/style.css
css_content = $(shell cat $(extra_css))
%.html: %.xml $(extra_css)
	${XML2RFC} $< $@
	$(sed_i) -e's~</style>~</style><style tyle="text/css">$(css_content)</style>~' $@
else
%.html: %.xml ${DTD} ${XSLT}
#	${SAXON} '$(subst \,\\,$(shell ${CYGPATH} $<))' '$(subst \,\\,$(shell ${CYGPATH} ${XSLT_HOME}/${XSLT}))' > $@
	${SAXON} $< ${XSLT_HOME}/${XSLT} > $@
endif

%.xhtml: %.xml ${DTD} ${XSLT}
	${SAXON} '$(subst \,\\,$(shell ${CYGPATH} $<))' '$(subst \,\\,$(shell ${CYGPATH} ${XSLT_HOME}/rfc2629toXHTML.xslt))' > $@

%.fo: %.xml ${DTD} ${XSLT} rfc2629-xhtml.ent rfc2629-other.ent
	${SAXON} $< ${XSLT_HOME}/rfc2629toFO.xslt > tmp.fo
	${SAXON} tmp.fo ${XSLT_HOME}/xsl11toFop.xslt > $@
	-rm -f tmp.fo

%.pdf: %.fo
	${FOP} $< -pdf $@

%.svg: %.fo
	${FOP} $< -svg $@
# The following is for the benefit of inkscape.
	perl -pi~ -e 's/fill:blue;visibility:hidden/fill:none;visibility:hidden/g' $@
	-rm -f $@~

%.ps: %.fo
	${FOP} $< -ps $@

%.txt: %.xml
	${XML2RFC} $< $@

%.nr: %.xml ${DTD} ${XSLT}
	${XML2RFC} $< $@

%.unpg: %.xml ${DTD} ${XSLT}
	${XML2RFC} $< $@

${XSLT}: ${XSLT_HOME}/${XSLT}
	cp $< $@

${DTD}:  ${XSLT_HOME}/${DTD}
	cp $< $@

rfc2629-xhtml.ent: ${XSLT_HOME}/rfc2629-xhtml.ent
	cp $< $@

rfc2629-other.ent: ${XSLT_HOME}/rfc2629-other.ent
	cp $< $@

.PHONY: nits validate skipdir
nits: ${BASE}.txt
	${IDNITS} --verbose $<

validate: $(wildcard xml/*.xml example*.xml)
	$(TOP)/xmlschema/build-strict
	${VALIDATE} $^

skipdir:
	@echo Skipping old ${BASE}.xml

submit:: ${BASE_NEXT}.txt

${BASE_NEXT}.xml: ${BASE}.xml
	sed -e"s/${BASE}-latest/${BASE_NEXT}/" < $< > $@

SUFFIXES := txt html xhtml unpg nr ps svg pdf
cleandir:
	-rm -f $(addprefix ${BASE}-[0-9][0-9].,xml ${SUFFIXES}) $(addprefix ${BASE}.,${SUFFIXES}) *.fo rfc2629-*.ent *.stackdump rfc2629.* *~
rclean:
	for i in *; do [ ! -d $$i ] || (cd $$i && $(MAKE) clean); done

tag:
	git tag ${BASE_NEXT}
retag:
	git tag -f ${BASE}-${REV_CURRENT}

GHPAGES_TMP := /tmp/ghpages$(shell echo $$$$)
.TRANSIENT: ${GHPAGES_TMP}
GITBRANCH := $(shell git branch | grep '\*' | cut -c3- -)
recurse:
	for i in *; do [ ! -d $$i ] || (cd $$i && $(MAKE) txt html); done

ghpages: recurse
	mkdir ${GHPAGES_TMP}
	find ${TOP} -type f \( -name '*.html' -o -name '*.txt' \) -exec cp {} ${GHPAGES_TMP} \;
	@find ${GHPAGES_TMP}
	git checkout gh-pages
	git pull
	mv -f ${GHPAGES_TMP}/* ${TOP}
	./mkindex > index.html
	git add ${TOP}/*.txt ${TOP}/*.html
	git commit -am "Script updating page."
	git checkout ${GITBRANCH}
	-rm -rf ${GHPAGES_TMP}
