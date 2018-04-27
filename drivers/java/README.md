## Quick + dirty java driver playground using maven

Tested on MacOS only

### Pre-requisites
* java (`brew cask install java`)
* maven (`brew install maven`)
* openssl (maybe?)

gen.sh Name [archtype]
---
Build skeleton app using the `simple` maven template or archetype.  Overwrites the generated pom.xml with pom.tpl

[Maven archetypes](https://maven.apache.org/guides/introduction/introduction-to-archetypes.html)


build.sh
---
Runs the package phase for all modules listed in root pom.xml

run.sh name ["args"]
---
Leverages [mavens exec plugin](https://www.mojohaus.org/exec-maven-plugin/index.html) to execute the app passing any arguments given to the script.
e.g. ./run.sh ssl "-uri mongodb://hostname/?ssl=true"

pom.xml (root)
---
Parent pom which acts as a dumping ground for shared dependencies and controls which subfolders to process

pom.tpl
---
Template pom used in generating new skeletons

