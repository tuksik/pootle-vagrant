#!/bin/bash

lOCS="/usr/local/lib/python2.7/dist-packages/pootle/translations/mattermost/"

function safecmd(){
	typeset cmnd="$*"
	typeset ret_code

	eval $cmnd
	ret_code=$?
	if [ $ret_code != 0 ]; then
		echo "Error: '$cmnd'" $ret_code
		#/usr/local/bin/mail.sh "elias@mattermost.com" "Pootle Error" "Error: $cmnd $ret_code"
		exit $ret_code
	fi
}

function update_template() {
    #Convert POT
    I18N2PO="i18n2po"

    #json templates from github
    TWEBSTATIC="/tmp/web_static.json"
    TPLATFORM="/tmp/platform.json"

    #Get new json
    URL="https://raw.githubusercontent.com/mattermost/platform/master"
    wget $URL/webapp/i18n/en.json -O $TWEBSTATIC
    wget $URL/i18n/en.json -O $TPLATFORM

    #Overwrite POT templates
    POTTEMPLATE="/usr/local/lib/python2.7/dist-packages/pootle/translations/mattermost/templates/"

    $I18N2PO -pot -o $POTTEMPLATE"web_static.pot" $TWEBSTATIC
    $I18N2PO -pot -o $POTTEMPLATE"platform.pot" $TPLATFORM

    cp $TWEBSTATIC $POTTEMPLATE
    cp $TPLATFORM $POTTEMPLATE

    #save template in database
    pootle update_stores --no-rq --project=mattermost --language=templates  --force --overwrite --config /etc/pootle.conf
}

function update_po() {
	CODE=$1
	echo "################Start $CODE##########################"
	echo "store all database in filesystem (po's)"
	safecmd pootle sync_stores --no-rq --project=mattermost --language=$CODE --force --overwrite --config /etc/pootle.conf

	echo "create new po with new template and old po translation"
	safecmd pot2po -t "$lOCS/$CODE/web_static.po" "$lOCS/templates/web_static.pot" "$lOCS/$CODE/web_static_new.po"
	safecmd pot2po -t "$lOCS/$CODE/platform.po"   "$lOCS/templates/platform.pot"   "$lOCS/$CODE/platform_new.po"

	echo "overwrite old po"
	mv "$lOCS/$CODE/web_static_new.po" "$lOCS/$CODE/web_static.po"
	mv "$lOCS/$CODE/platform_new.po"   "$lOCS/$CODE/platform.po"

	echo "save new po in database"
	safecmd pootle update_stores --no-rq --project=mattermost --language=$CODE --config /etc/pootle.conf
	echo "################Finished $CODE########################"
}

function sync() {
    for l in $(ls -1 $lOCS | grep -v templates); do
	    update_po "$l"
    done

    echo "SUCCESS sync po's"
}

# this function needs the pootle user
function pootle_process(){
	echo "update templates"
	update_template

	echo "update PO"
	sync

	echo "Recreate stats in redis"
	pootle refresh_stats --no-rq --project=mattermost --config /etc/pootle.conf

	echo "Restart pootle"
	sudo start pootle
}
 
echo "Stop Service"
sudo stop pootle
sleep 10

echo "Clear cache"
redis-cli flushall

echo "Execute pootle process with pootle user"
pootle_process

echo "SUCCESS"


