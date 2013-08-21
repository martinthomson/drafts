ifeq "$(shell uname -o 2>/dev/null)" "Cygwin"
    CYGPATH := cygpath --windows
else
    CYGPATH := echo
endif

BASE := $(lastword $(basename $(wildcard draft-*.xml)))
XML := ${BASE}.xml
DTD := rfc2629.dtd
XSLT := rfc2629.xslt

XML_HOME := ${TOP}
# SAXON := java -jar '$(subst \,\\,$(shell ${CYGPATH} ${XML_HOME}/saxon8.jar))'
VALIDATE := ${XML_HOME}/validate
SAXON := java -jar '$(shell ${CYGPATH} ${XML_HOME}/saxon8.jar)'
XML2RFC_HOME := ${XML_HOME}/xml2rfc-1.35pre1
ifeq "${METHOD}" "direct"
XML2RFC := ${XML2RFC_HOME}/xml2rfc.sh
else
XML2RFC := ${XML_HOME}/webxml2rfc.sh
endif
XSLT_HOME := ${XML_HOME}/rfc2629xslt
HTML_XSLT := false
IDNITS := ${XML_HOME}/idnits/idnits

REV_CURRENT := $(shell git tag | grep "${BASE}" | tail -1 | sed -e"s/.*-//")
ifeq "${REV_CURRENT}" ""
REV_NEXT ?= 00
else
REV_NEXT ?= $(shell printf "%02d" `echo '${REV_CURRENT}+1' | bc`)
endif
BASE_NEXT := ${BASE}-${REV_NEXT}

TARGET ?= txt

EXTRA := html pdf xhtml svg nr unpg

.PHONY: default all extra nits validate clean submit
ifeq "${TOP}" ""
default:
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
%.html: %.xml
	${XML2RFC} $< $@
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

${BASE_NEXT}.xml:
	sed -e"s/${BASE}-latest/${BASE_NEXT}/" < ${BASE}.xml > ${BASE_NEXT}.xml

clean:
	-rm -f $(addprefix ${BASE}.,${TARGET} ${EXTRA}) *.fo rfc2629-*.ent *.stackdump rfc2629.* *~

GHPAGES_TMP := /tmp/ghpages$(shell echo $$$$)
.TRANSIENT: ${GHPAGES_TMP}
GITBRANCH := $(shell git branch | grep '\*' | cut -c3- -)
ghpages: 
	for i in *; do [ ! -d $$i ] || (cd $$i && $(MAKE) txt html); done
	find . -type f \( -name '*.html' -o -name '*.txt' \) -exec mv {} ${GHPAGES_TMP} \;
	@find ${GHPAGES_TMP}
	git checkout gh-pages
	git pull
	mv -f ${GHPAGES_TMP}/* .
	git add *.txt *.html
	git commit -am "Script updating page."
	git checkout ${GITBRANCH}
	#-rf -rf ${GHPAGES_TMP}
