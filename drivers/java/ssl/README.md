## Sample SSL client connection using self-signed cert

The scripts faciliate the creation of a self-signed cert and the java keystore.  The sample client code uses the java trust store with the same self-signed certificate as the server.  The `pom.xml` specifies the java truststore settings required for client certificate validation of the server.  An alternate approach would be to disable certificate validation in java altogether (not recommended).  The MongoDB Java driver delegates TLS verification to the java core libraries.

The following is an example of how to ignore certificate validation:  https://futurestud.io/tutorials/retrofit-2-how-to-trust-unsafe-ssl-certificates-self-signed-expired

Note:  Tested on MacOS only.

### Pre-requisites
* java (`brew cask install java`)
* maven (`brew install maven`)
* openssl for making certs
* keytool for making a keystore

makecert.sh
---
Creates a root-ca.pem unless it already exists in the current directory then iterates over the host list provided via the `-h` parameter to generate the certs.  By default it generates a single cert using `$(hostname -f)`.  Once complete the current directory should have all of the following:

* root-ca.key  - The private key for the root-ca
* root-ca.pem  - The RootCA certificate
* root-ca.srl  - The RootCA serial number runner
* hostname.crt - The self-signed certificated validated by root-ca.pem
* hostname.key - The private key
* hostname.pem - The combined key+cert used in MongoDB

Ensure `Common Name` (CN) or `Subject Alternate Name` (SAN) matches the fully qualified domain name for the host where the cert will be used (e.g. `hostname -f`) otherwise the clients will need to allow invalid hostnames during certificate validation or validation must be disabled altogether.


makekeystore.sh [password]
---
Creates a java keystore in the current directory with the given password (mongodb by default)

run.sh <hostname>
---
Leverages [mavens exec plugin](https://www.mojohaus.org/exec-maven-plugin/index.html) to execute the app with a default uri to the given host (default localhost)
e.g. `./run.sh`


