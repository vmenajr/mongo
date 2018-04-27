<?xml version="1.0" encoding="UTF-8"?>
<project xmlns="http://maven.apache.org/POM/4.0.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
  xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 http://maven.apache.org/xsd/maven-4.0.0.xsd">
  <modelVersion>4.0.0</modelVersion>
  <groupId>com.mongodb.app</groupId>
  <artifactId>NAME</artifactId>
  <version>1.0-SNAPSHOT</version>
  <name>NAME</name>
  <parent>
      <groupId>com.mongodb</groupId>
      <artifactId>top</artifactId>
      <version>1.0-SNAPSHOT</version>
  </parent>
  <build>
    <pluginManagement><!-- lock down plugins versions to avoid using Maven defaults (may be moved to parent pom) -->
      <plugins>
        <plugin>
          <groupId>org.codehaus.mojo</groupId>
          <artifactId>exec-maven-plugin</artifactId>
          <version>1.6.0</version>
          <executions>
            <execution>
              <goals>
                <goal>java</goal>
              </goals>
            </execution>
          </executions>
          <configuration>
            <mainClass>com.mongodb.app.App</mainClass>
            <!--<arguments>-->
              <!--<argument>argument1</argument>-->
              <!--...-->
            <!--</arguments>-->
            <!--<systemProperties>-->
              <!--<systemProperty>-->
                <!--<key>javax.net.ssl.trustStorePassword</key>-->
                <!--<value>mongodb</value>-->
              <!--</systemProperty>-->
            <!--</systemProperties>-->
          </configuration>
        </plugin>
      </plugins>
    </pluginManagement>
  </build>
</project>
