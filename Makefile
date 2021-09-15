curl=/usr/bin/curl
cat=/usr/bin/cat
slapcat=/usr/bin/sudo -u openldap /usr/sbin/slapcat
sourceDir=source
workingDir=working
dataDir=data

usage:
	@echo "targets:"
	@echo "\tupdates"
	@echo "\tcleanUpdates"
	@echo "\tlocalUpdates"
	@echo "\tclean"

clean:
	rm ${workingDir}/*

cleanUpdates: clean updates

localUpdates: triggerLocal updates


triggerFile=${workingDir}/triggerRebuild

triggerFull: clean

triggerLocal: 
	/usr/bin/touch ${localSources}

${triggerFile}: 
	/usr/bin/test -f ${triggerFile} || /usr/bin/touch ${triggerFile}

phonebookUrl=https://apps.wizworks.net:9091/results.php
phonebookHtmlFile=${workingDir}/directory.html
phonebookJsonFile=${workingDir}/directory.json
phonebookJsonBackupFile=${dataDir}/directory.json

audioUrl=https://apps.wizworks.net:9091/audio.php
audioHtmlFile=${workingDir}/audio.html
audioJsonFile=${workingDir}/audio.json
audioJsonBackupFile=${dataDir}/audio.json

linksUrl=https://apps.wizworks.net:9091/links.php
linksHtmlFile=${workingDir}/links.html
linksJsonFile=${workingDir}/links.json
linksJsonBackupFile=${dataDir}/links.json

bridgesUrl=https://apps.wizworks.net:9091/bridges.php
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
	${curl} -o ${phonebookHtmlFile} ${phonebookUrl}

${phonebookJsonFile}: ${phonebookHtmlFile}
	${cat} ${phonebookHtmlFile} | ./directoryHTML2json > ${phonebookJsonFile}

${phonebookJsonBackupFile}: ${phonebookJsonFile}
	-./compareBackupCopy ${phonebookJsonFile} ${phonebookJsonBackupFile} 1


${audioHtmlFile}: ${triggerFile}
	${curl} -o ${audioHtmlFile} ${audioUrl}

${audioJsonFile}: ${audioHtmlFile}
	${cat} ${audioHtmlFile} | ./audioHTML2json > ${audioJsonFile}

${audioJsonBackupFile}: ${audioJsonFile}
	-./compareBackupCopy ${audioJsonFile} ${audioJsonBackupFile} 20


${linksHtmlFile}: ${triggerFile}
	${curl} -o ${linksHtmlFile} ${linksUrl}

${linksJsonFile}: ${linksHtmlFile}
	${cat} ${linksHtmlFile} | ./linksHTML2json > ${linksJsonFile}

${linksJsonBackupFile}: ${linksJsonFile}
	-./compareBackupCopy ${linksJsonFile} ${linksJsonBackupFile} 20


${bridgesHtmlFile}: ${triggerFile}
	${curl} -o ${bridgesHtmlFile} ${bridgesUrl}

${bridgesJsonFile}: ${bridgesHtmlFile}
	${cat} ${bridgesHtmlFile} | ./bridgesHTML2json > ${bridgesJsonFile}

${bridgesJsonBackupFile}: ${bridgesJsonFile}
	-./compareBackupCopy ${bridgesJsonFile} ${bridgesJsonBackupFile} 20


${vanityJsonFile}: ${vanitySourceFile}
	${cat} ${vanitySourceFile} | ./vanitySource2json > ${vanityJsonFile}

${vanityJsonBackupFile}: ${vanityJsonFile}
	-./compareBackupCopy ${vanityJsonFile} ${vanityJsonBackupFile} 75


${currentLdif}: ${triggerFile}
	${slapcat} -b "dc=hamshackhotline,dc=com" > ${currentLdif}

${currentLdifBackupFile}: ${currentLdif}
	-./compareBackupCopy ${currentLdif} ${currentLdifBackupFile} 0


${currentJsonFile}: ${currentLdifBackupFile}
	${cat} ${currentLdifBackupFile} | ./ldif2json > ${currentJsonFile}

${currentJsonBackupFile}: ${currentJsonFile}
	-./compareBackupCopy ${currentJsonFile} ${currentJsonBackupFile} 10


${targetJsonFile}: ${sourceJsonBackupFiles}
	./combineTargets ${sourceJsonBackupFiles} > ${targetJsonFile}

${targetJsonBackupFile}: ${targetJsonFile}
	-./compareBackupCopy ${targetJsonFile} ${targetJsonBackupFile} 10


${updatesLdif}: ${currentJsonFile} ${targetJsonBackupFile}
	./diff2ldif ${currentJsonFile} ${targetJsonBackupFile} > ${updatesLdif}

# Need to do something different here.
# Only/Always backup if >0 entries
# Sanity check is different, ratio of this to current
${updatesLdifBackupFile}: ${updatesLdif}
	-./compareBackupCopy ${updatesLdif} ${updatesLdifBackupFile} 0


updates: ${updatesLdifBackupFile}
	@echo $$(${cat} ${updatesLdif} | grep ^dn: | wc -l) "update(s) generated"
	@echo "ldapmodify -D cn=admin,dc=hamshackhotline,dc=com -x -W -f data/updates.ldif"
