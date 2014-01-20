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

TARGET ?= txt

EXTRA := html pdf xhtml svg nr unpg

.PHONY: default all extra nits validate clean submit recurse tag
ifeq "${TOP}" ""
TOP := .
default: recurse
else
default: ${TARGET}
endif
extra: default ${EXTRA}
all: extra nits validate

.PHONY: txt html xhtml pdf svg nr unpg
txt: ${BASE}.txt
html: ${BASE}.html
xhtml: ${BASE}.xhtml
pdf: ${BASE}.pdf
svg: ${BASE}.svg
nr: ${BASE}.nr
unpg: ${BASE}.unpg

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

.PHONY: nits validate
nits: ${BASE}.txt
	${IDNITS} --verbose $<

validate: $(wildcard xml/*.xml example*.xml)
	$(TOP)/xmlschema/build-strict
	${VALIDATE} $^

submit: ${BASE_NEXT}.txt

${BASE_NEXT}.xml: ${BASE}.xml
	sed -e"s/${BASE}-latest/${BASE_NEXT}/" < $< > $@

clean:
	-rm -f $(addprefix ${BASE}.,${TARGET} ${EXTRA}) *.fo rfc2629-*.ent *.stackdump rfc2629.* *~

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
	find ${TOP} -type f \( -name '*.html' -o -name '*.txt' \) -exec mv {} ${GHPAGES_TMP} \;
	@find ${GHPAGES_TMP}
	git checkout gh-pages
	git pull
	mv -f ${GHPAGES_TMP}/* ${TOP}
	git add ${TOP}/*.txt ${TOP}/*.html
	git commit -am "Script updating page."
	git checkout ${GITBRANCH}
	-rm -rf ${GHPAGES_TMP}
