#!/bin/sh
# A replacement for xml2rfc that uses wget and the web service at xml.resource.org.

if [[ $# -lt 1 ]]; then
    echo "Usage: ${0##*/} <input> [output]" 1>&2
    exit 2
elif [[ $# -ge 2 ]]; then
    OUTPUT="$2"
else
    OUTPUT="${1%.xml}.txt"
fi

URI="${XML2RFC_URI:-http://xml.resource.org/cgi-bin/xml2rfc.cgi}"
# development URI: http://xml.resource.org/cgi-bin/xml2rfc-dev.cgi
declare -a MD5 OPTIONS
if [[ `uname -s 2>/dev/null` == "Darwin" ]]; then
    MD5=(md5)
else
    MD5=(md5sum -)
fi
BOUNDARY="boundary-"`head "$1" | "${MD5[@]}" | cut -c 1-32 -`
FILE=/tmp/${0##*/}$$
M=""

OPTIONS=(--header "Content-Type: multipart/form-data; boundary=$BOUNDARY")
OPTIONS=("${OPTIONS[@]}" --header 'Cache-Control: no-cache')
OPTIONS=("${OPTIONS[@]}" --referer 'http://xml.resource.org/')

if which wget > /dev/null 2>&1; then
    OPTIONS=("${OPTIONS[@]}" ${WGET_OPTIONS:- --quiet})
    OPTIONS=("${OPTIONS[@]}" --post-file "$FILE" --output-document "$OUTPUT")
    HTTP=wget
elif which curl > /dev/null 2>&1; then
    OPTIONS=("${OPTIONS[@]}" ${CURL_OPTIONS:- --silent})
    OPTIONS=("${OPTIONS[@]}" --data-binary '@'"$FILE" --output "$OUTPUT")
    HTTP=curl
else
    echo "Neither wget nor curl are on the path, can't proceed."
    exit 1
fi

trap 'rm -f $FILE' EXIT INT

cat <<EOF > "$FILE"
--$BOUNDARY$M
Content-Disposition: form-data; name="modeAsFormat"$M
$M
${OUTPUT##*.}/ascii$M
--$BOUNDARY$M
Content-Disposition: form-data; name="type"$M
$M
ascii$M
--$BOUNDARY$M
Content-Disposition: form-data; name="checking"$M
$M
strict$M
--$BOUNDARY$M
Content-Disposition: form-data; name="input"; filename="${1##*/}"$M
Content-Type: text/xml$M
$M
EOF
cat "$1" >> "$FILE"
echo "$M" >> "$FILE"
echo "--$BOUNDARY--$M" >> "$FILE"

$HTTP "${OPTIONS[@]}" "$URI"

if grep -l -q '<title>\(Unable to Convert File\|You lose\)</title>' "$OUTPUT" 1>/dev/null 2>&1; then
    cat "$OUTPUT" 1>&2 2>/dev/null
    rm -f "$OUTPUT"
    exit 1
fi

