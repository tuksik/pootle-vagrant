#!/bin/bash

if [ $# != 2 ] ; then
	echo "Usage: $0 es es"
	exit 1
fi

CODE=$1
CODEOUT=$2

MATTER="/usr/local/lib/python2.7/dist-packages/pootle/translations/mattermost/"
POOUT="$MATTER/$CODEOUT"

#Bin
I18N2PO="i18n2po"

function safecmd(){
        typeset cmnd="$*"
        typeset ret_code

        eval $cmnd
        ret_code=$?
        if [ $ret_code != 0 ]; then
                echo "Error: '$cmnd'" $ret_code
                exit $ret_code
        fi
}

#get the PO
safecmd wget "http://localhost/export/?path=/$CODEOUT/mattermost/web_static.po" -O /tmp/web_static.po
safecmd wget "http://localhost/export/?path=/$CODEOUT/mattermost/platform.po" -O /tmp/platform.po

#get json from github
safecmd wget https://raw.githubusercontent.com/mattermost/platform/master/webapp/i18n/$CODE.json -O $POOUT/web_static.json
safecmd wget https://raw.githubusercontent.com/mattermost/platform/master/i18n/$CODE.json -O $POOUT/platform.json

#Convert to po
safecmd $I18N2PO -o $POOUT/web_static.po -t /tmp/web_static.po $POOUT/web_static.json
safecmd $I18N2PO -o $POOUT/platform.po -t /tmp/platform.po $POOUT/platform.json

rm /tmp/web_static.po
rm /tmp/platform.po

#create new po with new template and old po translation
safecmd pot2po -t "$POOUT/web_static.po" "$MATTER/templates/web_static.pot" "$POOUT/web_static_new.po"
safecmd pot2po -t "$POOUT/platform.po"   "$MATTER/templates/platform.pot"   "$POOUT/platform_new.po"

#overwrite old po
mv "$POOUT/web_static_new.po" "$POOUT/web_static.po"
mv "$POOUT/platform_new.po"   "$POOUT/platform.po"

safecmd pootle update_stores --project=mattermost --language=$CODEOUT --config /etc/pootle.conf
safecmd pootle refresh_stats --project=mattermost --language=$CODEOUT --config /etc/pootle.conf
# --force --overwrite

echo "SUCCESS"


