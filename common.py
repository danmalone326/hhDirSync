# common.py
# common functions 
import mysql.connector

defaultPropertiesFilename = 'hhAgent.properties'
def readProperties(propertiesFilename = defaultPropertiesFilename):
    properties = {}
    with open(propertiesFilename, 'r') as f:
        for line in f:
            line = line.rstrip() #removes trailing whitespace and '\n' chars

            if "=" not in line: continue #skips blanks and comments w/o =
            if line.startswith("#"): continue #skips comments which contain =

            k, v = line.split("=", 1)
            properties[k] = v
    return properties

def connectDB(host,user,passwd,schema):
    try:
        config = {
            "host": host,
            "user": user,
            "password": passwd,
            "database": schema,
        }
        db = mysql.connector.connect(**config)
        cursor = db.cursor()
        cursor.execute("SELECT VERSION()")
        results = cursor.fetchone()
        # Check if anything at all is returned
        if results:
            return db
        else:
            return None
    except mysql.connector.errors.ProgrammingError as ex:
        # print("ERROR IN CONNECTION")
        print(ex)
        return None
