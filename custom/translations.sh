#!/usr/bin/env bash

#vars
DATE=$(date "+%Y%m%d")
PLT_DIR="/home/ubuntu/platform"
RN_DIR="/home/ubuntu/mattermost-mobile"
MERGE_DIR="/tmp/mattermost/"

PO2I18N="/home/ubuntu/pootle/po2i18n"
I18N4MM="i18n4mm"

SERVER="http://translate.mattermost.com"
TWEBSTATIC="$PLT_DIR/webapp/i18n/en.json"
TRNSTATIC="$RN_DIR/assets/base/i18n/en.json"
TPLATFORM="$PLT_DIR/i18n/en.json"

BRANCH="translations-$DATE"
PLT_RELEASE="master"
RN_RELEASE="master"
USER="mattermost"
PLT_REMOTE="upstream"
RN_REMOTE="origin"

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

#convert PO->Json
function convert_json() {
    INCODE=$1
	OUTCODE=$2

    safecmd mkdir -p "/tmp/mattermost/$OUTCODE/"
	#translated po from pootle
    WEBSTATIC="/tmp/mattermost/$OUTCODE/web_static.po"
    PLATFORM="/tmp/mattermost/$OUTCODE/platform.po"

	#output language in my fork
	OUTWEBSTATIC="$PLT_DIR/webapp/i18n/$OUTCODE.json"
	OUTPLATFORM="$PLT_DIR/i18n/$OUTCODE.json"
	OUTRNSTATIC="$RN_DIR/assets/base/i18n/$OUTCODE.json"

	#Get new PO
	wget "$SERVER/export/?path=/$INCODE/mattermost/web_static.po" -O $WEBSTATIC
	wget "$SERVER/export/?path=/$INCODE/mattermost/platform.po" -O $PLATFORM

    #Export to repository
	safecmd $PO2I18N -t $MERGE_DIR/en.json -o $OUTWEBSTATIC $WEBSTATIC
	safecmd $I18N4MM -s webapp -f $OUTWEBSTATIC -o $PLT_DIR/webapp/i18n
	safecmd cp $OUTWEBSTATIC $OUTRNSTATIC

	safecmd $PO2I18N -t $TPLATFORM -o $OUTPLATFORM $PLATFORM
	safecmd $I18N4MM -s platform -p id -f $OUTPLATFORM -o $PLT_DIR/i18n

	safecmd rm $WEBSTATIC
	safecmd rm $PLATFORM
}

# Returns "*" if the current git branch is dirty
function git_dirty {
	[[ $(git diff --shortstat 2> /dev/null | tail -n1) != "" ]] && echo "*"
}

#Prepare the repository
function fetch_repo() {
	safecmd cd $PLT_DIR
	safecmd git checkout $PLT_RELEASE
	safecmd git fetch --prune $PLT_REMOTE
	safecmd git merge $PLT_REMOTE/$PLT_RELEASE
	safecmd git checkout -b $BRANCH

    safecmd cd $RN_DIR
	safecmd git checkout $RN_RELEASE
	safecmd git fetch --prune $RN_REMOTE
	safecmd git merge $RN_REMOTE/$RN_RELEASE
	safecmd git checkout -b $BRANCH
}

function sort() {
    safecmd $I18N4MM -s platform -p id -f "$PLT_DIR/i18n/en.json" -o $PLT_DIR/i18n
    safecmd $I18N4MM -s webapp -f "$MERGE_DIR/en.json" -o $PLT_DIR/webapp/i18n
    safecmd cp $PLT_DIR/webapp/i18n/en.json $RN_DIR/assets/base/i18n/en.json
}

#Create a PR
function pullrequest() {
    safecmd cd $PLT_DIR
	git commit -am "translations PR $DATE"
	printf "translations PR $DATE\n\nIdeally this PR should be review by community members for each language.\n\nNote: In the event that you see an english translation instead of the desired language is because this PR was submitted before the translation was made on the Mattermost Translation Server and probably will be submitted for the next PR." > /tmp/hub.txt
	safecmd git push $PLT_REMOTE $BRANCH
	safecmd hub pull-request -F /tmp/hub.txt -b $USER/platform:$PLT_RELEASE -h $USER/platform:$BRANCH

	safecmd cd $RN_DIR
	git commit -am "translations PR $DATE"
	safecmd git push $RN_REMOTE $BRANCH
	safecmd hub pull-request -F /tmp/hub.txt -b $USER/platform:$RN_RELEASE -h $USER/mattermost-mobile:$BRANCH
}

#Merge platform and react native json files
safecmd $I18N4MM -m -r $TRNSTATIC -f $TWEBSTATIC -o $MERGE_DIR

fetch_repo
sort

#Convert all languages
convert_json "de" "de"
convert_json "es" "es"
convert_json "fr" "fr"
convert_json "ja" "ja"
convert_json "ko" "ko"
convert_json "nl" "nl"
convert_json "pt_BR" "pt-BR"
convert_json "ru" "ru"
convert_json "zh_TW" "zh-TW"
convert_json "zh_CN" "zh-CN"

pullrequest
