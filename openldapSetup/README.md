# hhDirSync/openldapSetup

This is a set of additions/changes that can be used after the openldap installation is complete.

## Schema extension

Extend the schema by adding 2 attributes and an objectclass.
* attributes
    * callsign
    * hamshackhotlineComEntryID
* objectclass
    * hamshackhotlineComEntry

The file `extendSchema.ldif` will add the needed attributes and objectclass to the schema.
```
sudo ldapmodify -Q -Y EXTERNAL -H ldapi:/// -c -f extendSchema.ldif
```

Verify the schema is valid.
```
sudo slapschema
```

## Add indexes

The file `addIndex.ldif` will add indexes for new and existing attributes. 
```
sudo ldapmodify -Q -Y EXTERNAL -H ldapi:/// -f addIndex.ldif
```

If there are existing entries, the database should be reindexed. This should be run while the service is stopped.
```
sudo service slapd stop
sudo -u openldap slapindex
sudo service slapd start
```

## Enable/Disable Logging

Enable stats logging to help with debugging connections and queries. 
```
sudo ldapmodify -Q -Y EXTERNAL -H ldapi:/// -f logLevelDebug.ldif
```

And to disable:
```
sudo ldapmodify -Q -Y EXTERNAL -H ldapi:/// -f logLevelNone.ldif
```
