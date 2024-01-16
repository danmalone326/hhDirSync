propertyFile=hhAgent.properties
ifeq ("$(wildcard $(propertyFile))","")
$(error $(propertyFile) does not exist.)
endif

getProperty = $(shell grep "^$(1)=" ${propertyFile} | cut -d"=" -f2-)

baseDir := $(call getProperty,baseDir)
ldapBaseDN := $(call getProperty,ldapBaseDN)
ldapAgentBindDN := $(call getProperty,ldapAgentBindDN)
ldapAgentBindPassword := $(call getProperty,ldapAgentBindPassword)

# Shouldn't need to change anything else
directoryUrlPrefix=https://apps.hamshackhotline.com
phonebookUrl=${directoryUrlPrefix}/results.php
audioUrl=${directoryUrlPrefix}/audio.php
linksUrl=${directoryUrlPrefix}/links.php
arduinoUrl=${directoryUrlPrefix}/arduino.php
bridgesUrl=${directoryUrlPrefix}/bridges.php

scriptDir=${baseDir}
sourceDir=${baseDir}/source
workingDir=${baseDir}/working
dataDir=${baseDir}/data

ldapAgentPasswordFile=${scriptDir}/ldapAgentPassword.properties

cat=/usr/bin/cat
grep=/usr/bin/grep
wc=/usr/bin/wc
savelog=/usr/bin/savelog
rm=/usr/bin/rm
cp=/usr/bin/cp
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
	@echo "\tsanityCheckOverride"

sanityCheckOverride:
	@echo "targets to override sanity checks:"
	@echo "\tphonebookJsonOverrideSanityCheck"
	@echo "\taudioJsonOverrideSanityCheck"
	@echo "\tlinksJsonOverrideSanityCheck"
	@echo "\tbridgesJsonOverrideSanityCheck"
	@echo "\tvanityJsonOverrideSanityCheck"
	@echo "\tcurrentLdifOverrideSanityCheck"
	@echo "\tcurrentJsonOverrideSanityCheck"
	@echo "\ttargetJsonOverrideSanityCheck"
	@echo "\tupdatesLdifOverrideSanityCheck"


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

phonebookJsonFile=${workingDir}/directory.json
phonebookJsonBackupFile=${dataDir}/directory.json

audioJsonFile=${workingDir}/audio.json
audioJsonBackupFile=${dataDir}/audio.json

linksJsonFile=${workingDir}/links.json
linksJsonBackupFile=${dataDir}/links.json

arduinoJsonFile=${workingDir}/arduino.json
arduinoJsonBackupFile=${dataDir}/arduino.json

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

localSources=${phonebookJsonFile} ${audioJsonFile} ${linksJsonFile} ${arduinoJsonFile} ${bridgesJsonFile}
sourceJsonBackupFiles=${phonebookJsonBackupFile} ${audioJsonBackupFile} ${linksJsonBackupFile} ${arduinoJsonBackupFile} ${bridgesJsonBackupFile} ${vanityJsonBackupFile}


${phonebookJsonFile}: ${triggerFile}
	./hhUsers2json > ${phonebookJsonFile}

${phonebookJsonBackupFile}: ${phonebookJsonFile}
	-${scriptDir}/compareBackupCopy -s ${phonebookJsonFile} -d ${phonebookJsonBackupFile} -p 10

phonebookJsonOverrideSanityCheck: 
	@${savelog} ${phonebookJsonBackupFile}


${audioJsonFile}: ${triggerFile}
	./audioServices2json > ${audioJsonFile}

${audioJsonBackupFile}: ${audioJsonFile}
	-${scriptDir}/compareBackupCopy -s ${audioJsonFile} -d ${audioJsonBackupFile} -p 20

audioJsonOverrideSanityCheck: 
	@${savelog} ${audioJsonBackupFile}


${linksJsonFile}: ${triggerFile}
	./hhRflinks2json > ${linksJsonFile}

${linksJsonBackupFile}: ${linksJsonFile}
	-${scriptDir}/compareBackupCopy -s ${linksJsonFile} -d ${linksJsonBackupFile} -p 20

linksJsonOverrideSanityCheck: 
	@${savelog} ${linksJsonBackupFile}


${arduinoJsonFile}: ${triggerFile}
	./hhArduino2json > ${arduinoJsonFile}

${arduinoJsonBackupFile}: ${arduinoJsonFile}
	-${scriptDir}/compareBackupCopy -s ${arduinoJsonFile} -d ${arduinoJsonBackupFile} -p 20

arduinoJsonOverrideSanityCheck: 
	@${savelog} ${arduinoJsonBackupFile}


${bridgesJsonFile}: ${triggerFile}
	./hhBridge2json > ${bridgesJsonFile}

${bridgesJsonBackupFile}: ${bridgesJsonFile}
	-${scriptDir}/compareBackupCopy -s ${bridgesJsonFile} -d ${bridgesJsonBackupFile} -p 20

bridgesJsonOverrideSanityCheck: 
	@${savelog} ${bridgesJsonBackupFile}


${vanityJsonFile}: ${vanitySourceFile}
	${cat} ${vanitySourceFile} | ./vanitySource2json > ${vanityJsonFile}

${vanityJsonBackupFile}: ${vanityJsonFile}
	-${scriptDir}/compareBackupCopy -s ${vanityJsonFile} -d ${vanityJsonBackupFile} -p 75

vanityJsonOverrideSanityCheck: 
	@${savelog} ${vanityJsonBackupFile}


${currentLdif}: ${triggerFile}
	${slapcat} -b "${ldapBaseDN}" > ${currentLdif}

${currentLdifBackupFile}: ${currentLdif} 
	-${scriptDir}/compareBackupCopy -s ${currentLdif} -d ${currentLdifBackupFile} -p 50

currentLdifOverrideSanityCheck: 
	@${savelog} ${currentLdifBackupFile}


${currentJsonFile}: ${currentLdifBackupFile}
	${cat} ${currentLdifBackupFile} | ./ldif2json > ${currentJsonFile}

${currentJsonBackupFile}: ${currentJsonFile}
	-${scriptDir}/compareBackupCopy -s ${currentJsonFile} -d ${currentJsonBackupFile} -p 10

currentJsonOverrideSanityCheck: 
	@${savelog} ${currentJsonBackupFile}


${targetJsonFile}: ${sourceJsonBackupFiles}
	${scriptDir}/combineTargets ${sourceJsonBackupFiles} > ${targetJsonFile}

${targetJsonBackupFile}: ${targetJsonFile}
	${scriptDir}/compareBackupCopy -s ${targetJsonFile} -d ${targetJsonBackupFile} -p 10

targetJsonOverrideSanityCheck: 
	@${savelog} ${targetJsonBackupFile}


${updatesLdif}: ${currentJsonBackupFile} ${targetJsonBackupFile}
	${scriptDir}/diff2ldif ${currentJsonBackupFile} ${targetJsonBackupFile} > ${updatesLdif}

# Need to do something different here.
# Only/Always backup if >0 entries
# Sanity check is different, ratio of this to current
${updatesLdifBackupFile}: ${updatesLdif}
	-${scriptDir}/compareBackupCopy -s ${updatesLdif} -d ${updatesLdifBackupFile} -p 10 -c ${currentLdifBackupFile} -n -u 

updatesLdifOverrideSanityCheck: 
	@${savelog} ${updatesLdifBackupFile}
	@${cp} ${updatesLdif} ${updatesLdifBackupFile}


${lastUpdateTimestampFile}: ${updatesLdifBackupFile}
	@${touch} ${lastUpdateTimestampFile}
	@echo $$(${cat} ${updatesLdifBackupFile} | ${grep} ^dn: | ${wc} -l) "update(s) generated"
	@echo -n ${ldapAgentBindPassword} > ${ldapAgentPasswordFile}
	@chmod og-rwx ${ldapAgentPasswordFile}
	${ldapmodify} -c -D ${ldapAgentBindDN} -x -y ${ldapAgentPasswordFile} -f ${updatesLdifBackupFile}
	@${rm} -f ${ldapAgentPasswordFile}


updates: ${lastUpdateTimestampFile}
