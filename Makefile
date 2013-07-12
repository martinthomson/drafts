ifeq "$(shell uname -o 2>/dev/null)" "Cygwin"
    CYGPATH := cygpath --windows
else
    CYGPATH := echo
endif

ifeq "${TOP}" ""
error "$${TOP} must be specified"
endif
ifeq "${BASE}" ""
error "$${BASE} must be specified"
endif
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
ifeq "$(shell uname -s 2>/dev/null)" "Darwin"
    sed_i := sed -i ''
else
    sed_i := sed -i
endif


REV_CURRENT = $(shell git tag | grep "${BASE}" | tail -1 | awk -F- '{print $$NF}')
REV_NEXT = $(shell printf "%.2d" `echo ${current_rev}+1 | bc`)
BASE_NEXT = $(draft_title)-$(next_rev)

TARGET ?= txt

EXTRA := html pdf xhtml svg nr unpg

.PHONY: default all extra nits validate clean submit
default: ${TARGET}
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
	cp $(draft_title).xml $(next_rev_name).xml
	$(sed_i) -e"s/$(draft_title)-latest/$(next_rev_name)/" $(next_rev_name).xml

clean:
	-rm -f $(addprefix ${BASE}.,${TARGET} ${EXTRA}) *.fo rfc2629-*.ent *.stackdump rfc2629.* *~
