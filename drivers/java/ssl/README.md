## Quick + dirty java driver playground using maven

Tested on MacOS only

### Pre-requisites
* java (`brew cask install java`)
* maven (`brew install maven`)
* openssl for making certs
* keytool for making a keystore

makecert.sh
---
Creates three files after prompting the user for various pieces of information:

* mongodb.crt - the self-signed certificate with CA: true
* mongodb.key - the private key
* mongodb.pem - the combined key+cert used in MongoDB

Ensure `Common Name` (CN) or `Subject Alternate Name` (SAN) matches the fully qualified domain name for the host where the cert will be used (e.g. `hostname -f`) otherwise the clients will need to allow invalid hostnames during certificate validation or validation must be disabled altogether.


makekeystore.sh <password>
---
Creates a java keystore in the current directory with the given password (mongodb by default)

run.sh <hostname>
---
Leverages [mavens exec plugin](https://www.mojohaus.org/exec-maven-plugin/index.html) to execute the app with a default uri to the given host (default localhost)
e.g. `./run.sh`


