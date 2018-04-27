#!/usr/bin/env bash
name=${1:?Missing name}
type=${2:-simple}
catalog=local,remote
version="1.0-SNAPSHOT"
mvn archetype:generate \
    -DinteractiveMode=false \
    -Dversion=${version} \
    -DarchetypeCatalog=${catalog} \
    -DarchetypeGroupId=org.apache.maven.archetypes \
    -DarchetypeArtifactId=maven-archetype-${type} \
    -DgroupId=com.mongodb.app \
    -DartifactId=${1}

if [ -d ${name} ]; then
	rm -rf ${name}/src/{test,site};
    sed -e "s/NAME/${name}/g" pom.tpl &> ${name}/pom.xml
fi
