curl=/usr/bin/curl
cat=/usr/bin/cat
slapcat=/usr/bin/sudo -u openldap /usr/sbin/slapcat
sourceDir=source
workingDir=working
dataDir=data

usage:
	@echo targets:
	@echo \tupdates
	@echo \tcleanUpdates
	@echo \tlocalUpdates
	@echo \tclean

clean:
	rm ${workingDir}/*

cleanUpdates: clean updates

localUpdates: triggerLocal updates


triggerFile=${workingDir}/triggerRebuild

triggerFull: clean

triggerLocal: 
	touch ${localSources}

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
currentJsonFile=${workingDir}/current.json
currentJsonBackupFile=${dataDir}/current.json

updatesLdif=${workingDir}/updates.ldif
updatesBackupLdif=${dataDir}/updates.ldif

localSources=${phonebookHtmlFile} ${audioHtmlFile} ${linksHtmlFile} ${bridgesHtmlFile}
sourceJsonBackupFiles=${phonebookJsonBackupFile} ${audioJsonBackupFile} ${linksJsonBackupFile} ${bridgesJsonBackupFile} ${vanityJsonBackupFile}

${phonebookHtmlFile}: ${triggerFile}
	${curl} -o ${phonebookHtmlFile} ${phonebookUrl}

${phonebookJsonFile}: ${phonebookHtmlFile}
	${cat} ${phonebookHtmlFile} | ./directoryHTML2json > ${phonebookJsonFile}

${phonebookJsonBackupFile}: ${phonebookJsonFile}
	-./jsonCompareBackupCopy ${phonebookJsonFile} ${phonebookJsonBackupFile} 1


${audioHtmlFile}: ${triggerFile}
	${curl} -o ${audioHtmlFile} ${audioUrl}

${audioJsonFile}: ${audioHtmlFile}
	${cat} ${audioHtmlFile} | ./audioHTML2json > ${audioJsonFile}

${audioJsonBackupFile}: ${audioJsonFile}
	-./jsonCompareBackupCopy ${audioJsonFile} ${audioJsonBackupFile} 20


${linksHtmlFile}: ${triggerFile}
	${curl} -o ${linksHtmlFile} ${linksUrl}

${linksJsonFile}: ${linksHtmlFile}
	${cat} ${linksHtmlFile} | ./linksHTML2json > ${linksJsonFile}

${linksJsonBackupFile}: ${linksJsonFile}
	-./jsonCompareBackupCopy ${linksJsonFile} ${linksJsonBackupFile} 20


${bridgesHtmlFile}: ${triggerFile}
	${curl} -o ${bridgesHtmlFile} ${bridgesUrl}

${bridgesJsonFile}: ${bridgesHtmlFile}
	${cat} ${bridgesHtmlFile} | ./bridgesHTML2json > ${bridgesJsonFile}

${bridgesJsonBackupFile}: ${bridgesJsonFile}
	-./jsonCompareBackupCopy ${bridgesJsonFile} ${bridgesJsonBackupFile} 20


${vanityJsonFile}: ${vanitySourceFile}
	${cat} ${vanitySourceFile} | ./vanitySource2json > ${vanityJsonFile}

${vanityJsonBackupFile}: ${vanityJsonFile}
	-./jsonCompareBackupCopy ${vanityJsonFile} ${vanityJsonBackupFile} 75


${currentLdif}: ${triggerFile}
	${slapcat} -b "dc=hamshackhotline,dc=com" > ${currentLdif}

${currentJsonFile}: ${currentLdif}
	${cat} ${currentLdif} | ./ldif2json > ${currentJsonFile}

${currentJsonBackupFile}: ${currentJsonFile}
	-./jsonCompareBackupCopy ${currentJsonFile} ${currentJsonBackupFile} 10


${targetJsonFile}: ${sourceJsonBackupFiles}
	./combineTargets ${sourceJsonBackupFiles} > ${targetJsonFile}

${targetJsonBackupFile}: ${targetJsonFile}
	-./jsonCompareBackupCopy ${targetJsonFile} ${targetJsonBackupFile} 10


${updatesLdif}: ${currentJsonFile} ${targetJsonBackupFile}
	./diff2ldif ${currentJsonFile} ${targetJsonBackupFile} > ${updatesLdif}


updates: ${updatesLdif}
	@echo $$(${cat} ${updatesLdif} | grep ^dn: | wc -l) "update(s) generated"
