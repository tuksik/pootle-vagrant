#!/bin/bash
lOCS="/usr/local/lib/python2.7/dist-packages/pootle/translations/mattermost/"
POTTEMPLATE="/usr/local/lib/python2.7/dist-packages/pootle/translations/mattermost/templates/"

PLT_RELEASE="master"
RN_RELEASE="master"

#Convert POT
I18N2PO="/home/vagrant/pootle/i18n2po"

#json templates from github
TWEBSTATIC="/tmp/web_static.json"
TPLATFORM="/tmp/platform.json"
RNSTATIC="/tmp/mobile.json"

#Get new json from repos
PLT_URL="https://raw.githubusercontent.com/mattermost/platform/$PLT_RELEASE"
RN_URL="https://raw.githubusercontent.com/mattermost/mattermost-mobile/$RN_RELEASE"

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
    wget $PLT_URL/webapp/i18n/en.json -O $TWEBSTATIC
    wget $PLT_URL/i18n/en.json -O $TPLATFORM
    wget $RN_URL/assets/base/i18n/en.json -O $RNSTATIC

    #merge WebApp and RN
    safecmd i18n4mm -m -r $RNSTATIC -f $TWEBSTATIC -o /tmp

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

	#store all database in filesystem (po's)
	echo "store database in filesystem"
	safecmd pootle sync_stores --no-rq --project=mattermost --language=$CODE --force --overwrite --config /etc/pootle.conf

	#create new po with new template and old po translation
	echo "creating new template and old po translation"
	safecmd pot2po -t "$lOCS/$CODE/web_static.po" "$lOCS/templates/web_static.pot" "$lOCS/$CODE/web_static_new.po"
	safecmd pot2po -t "$lOCS/$CODE/platform.po"   "$lOCS/templates/platform.pot"   "$lOCS/$CODE/platform_new.po"

	#overwrite old po
	echo "overwrite old po"
	mv "$lOCS/$CODE/web_static_new.po" "$lOCS/$CODE/web_static.po"
	mv "$lOCS/$CODE/platform_new.po"   "$lOCS/$CODE/platform.po"

	#save new po in database
	echo "store new po in database"
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
	sleep 10

	#echo "Get translation from server"
	#/usr/local/bin/update_lang.sh 'es' 'es'
	#/usr/local/bin/update_lang.sh 'pt' 'pt_BR'
}

echo "Stop Service"
sudo stop pootle
sleep 10

echo "Clear cache"
redis-cli flushall

echo "Execute process"
pootle_process

echo "SUCCESS"
exit 0

