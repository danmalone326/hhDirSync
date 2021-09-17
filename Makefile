baseDir=/home/hhagent/hhDirSync
ldapBaseDN=dc=hamshackhotline,dc=com
ldapAgentBindDN=cn=hhagent,dc=hamshackhotline,dc=com

# Shouldn't need to change anything else
phonebookUrl=https://apps.wizworks.net:9091/results.php
audioUrl=https://apps.wizworks.net:9091/audio.php
linksUrl=https://apps.wizworks.net:9091/links.php
bridgesUrl=https://apps.wizworks.net:9091/bridges.php

scriptDir=${baseDir}
sourceDir=${baseDir}/source
workingDir=${baseDir}/working
dataDir=${baseDir}/data

ldapAgentPasswordFile=${scriptDir}/ldapAgentPassword

curl=/usr/bin/curl
cat=/usr/bin/cat
grep=/usr/bin/grep
wc=/usr/bin/wc
rm=/usr/bin/rm
touch=/usr/bin/touch
test=/usr/bin/test
ldapmodify=/usr/bin/ldapmodify
slapcat=/usr/bin/sudo -u openldap /usr/sbin/slapcat


usage:
	@echo "targets:"
	@echo "\tupdates"
	@echo "\tcleanUpdates"
	@echo "\tlocalUpdates"
	@echo "\tclean"

clean:
	-rm -f ${workingDir}/*

cleanUpdates: clean updates

localUpdates: triggerLocal updates

lastUpdateTimestampFile=${dataDir}/lastUpdateTimestamp
triggerFile=${workingDir}/triggerRebuild

triggerFull: clean

triggerLocal: 
	${touch} ${localSources}
	-${rm} -f ${currentLdif}

${triggerFile}: 
	${test} -f ${triggerFile} || ${touch} ${triggerFile}

phonebookHtmlFile=${workingDir}/directory.html
phonebookJsonFile=${workingDir}/directory.json
phonebookJsonBackupFile=${dataDir}/directory.json

audioHtmlFile=${workingDir}/audio.html
audioJsonFile=${workingDir}/audio.json
audioJsonBackupFile=${dataDir}/audio.json

linksHtmlFile=${workingDir}/links.html
linksJsonFile=${workingDir}/links.json
linksJsonBackupFile=${dataDir}/links.json

bridgesHtmlFile=${workingDir}/bridges.html
bridgesJsonFile=${workingDir}/bridges.json
bridgesJsonBackupFile=${dataDir}/bridges.json

vanitySourceFile=${sourceDir}/vanitySource.json
vanityJsonFile=${workingDir}/vanity.json
vanityJsonBackupFile=${dataDir}/vanity.json

targetJsonFile=${workingDir}/target.json
targetJsonBackupFile=${dataDir}/target.json

currentLdif=${workingDir}/current.ldif
currentLdifBackupFile=${dataDir}/current.ldif
currentJsonFile=${workingDir}/current.json
currentJsonBackupFile=${dataDir}/current.json

updatesLdif=${workingDir}/updates.ldif
updatesLdifBackupFile=${dataDir}/updates.ldif

localSources=${phonebookHtmlFile} ${audioHtmlFile} ${linksHtmlFile} ${bridgesHtmlFile}
sourceJsonBackupFiles=${phonebookJsonBackupFile} ${audioJsonBackupFile} ${linksJsonBackupFile} ${bridgesJsonBackupFile} ${vanityJsonBackupFile}

${phonebookHtmlFile}: ${triggerFile}
	${curl} -s -o ${phonebookHtmlFile} ${phonebookUrl}

${phonebookJsonFile}: ${phonebookHtmlFile}
	${cat} ${phonebookHtmlFile} | ./directoryHTML2json > ${phonebookJsonFile}

${phonebookJsonBackupFile}: ${phonebookJsonFile}
	-${scriptDir}/compareBackupCopy -s ${phonebookJsonFile} -d ${phonebookJsonBackupFile} -p 1


${audioHtmlFile}: ${triggerFile}
	${curl} -s -o ${audioHtmlFile} ${audioUrl}

${audioJsonFile}: ${audioHtmlFile}
	${cat} ${audioHtmlFile} | ./audioHTML2json > ${audioJsonFile}

${audioJsonBackupFile}: ${audioJsonFile}
	-${scriptDir}/compareBackupCopy -s ${audioJsonFile} -d ${audioJsonBackupFile} -p 20


${linksHtmlFile}: ${triggerFile}
	${curl} -s -o ${linksHtmlFile} ${linksUrl}

${linksJsonFile}: ${linksHtmlFile}
	${cat} ${linksHtmlFile} | ./linksHTML2json > ${linksJsonFile}

${linksJsonBackupFile}: ${linksJsonFile}
	-${scriptDir}/compareBackupCopy -s ${linksJsonFile} -d ${linksJsonBackupFile} -p 20


${bridgesHtmlFile}: ${triggerFile}
	${curl} -s -o ${bridgesHtmlFile} ${bridgesUrl}

${bridgesJsonFile}: ${bridgesHtmlFile}
	${cat} ${bridgesHtmlFile} | ./bridgesHTML2json > ${bridgesJsonFile}

${bridgesJsonBackupFile}: ${bridgesJsonFile}
	-${scriptDir}/compareBackupCopy -s ${bridgesJsonFile} -d ${bridgesJsonBackupFile} -p 20


${vanityJsonFile}: ${vanitySourceFile}
	${cat} ${vanitySourceFile} | ./vanitySource2json > ${vanityJsonFile}

${vanityJsonBackupFile}: ${vanityJsonFile}
	-${scriptDir}/compareBackupCopy -s ${vanityJsonFile} -d ${vanityJsonBackupFile} -p 75


${currentLdif}: ${triggerFile}
	${slapcat} -b "${ldapBaseDN}" > ${currentLdif}

${currentLdifBackupFile}: ${currentLdif} 
	-${scriptDir}/compareBackupCopy -s ${currentLdif} -d ${currentLdifBackupFile} -p 0


${currentJsonFile}: ${currentLdifBackupFile}
	${cat} ${currentLdifBackupFile} | ./ldif2json > ${currentJsonFile}

${currentJsonBackupFile}: ${currentJsonFile}
	-${scriptDir}/compareBackupCopy -s ${currentJsonFile} -d ${currentJsonBackupFile} -p 10


${targetJsonFile}: ${sourceJsonBackupFiles}
	${scriptDir}/combineTargets ${sourceJsonBackupFiles} > ${targetJsonFile}

${targetJsonBackupFile}: ${targetJsonFile}
	-${scriptDir}/compareBackupCopy -s ${targetJsonFile} -d ${targetJsonBackupFile} -p 10


${updatesLdif}: ${currentJsonBackupFile} ${targetJsonBackupFile}
	${scriptDir}/diff2ldif ${currentJsonBackupFile} ${targetJsonBackupFile} > ${updatesLdif}

# Need to do something different here.
# Only/Always backup if >0 entries
# Sanity check is different, ratio of this to current
${updatesLdifBackupFile}: ${updatesLdif}
	-${scriptDir}/compareBackupCopy -s ${updatesLdif} -d ${updatesLdifBackupFile} -p 10 -c ${currentLdifBackupFile} -n -u 


${lastUpdateTimestampFile}: ${updatesLdifBackupFile}
	touch ${lastUpdateTimestampFile}
	@echo $$(${cat} ${updatesLdifBackupFile} | ${grep} ^dn: | ${wc} -l) "update(s) generated"
	${ldapmodify} -D ${ldapAgentBindDN} -x -y ${ldapAgentPasswordFile} -f ${updatesLdifBackupFile}


updates: ${lastUpdateTimestampFile}