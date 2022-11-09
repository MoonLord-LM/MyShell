rm -rf '/home/MySpringBoot'

cd '/home'
git clone --depth=1 'https://github.com/MoonLord-LM/MySpringBoot.git'
cd 'MySpringBoot'

mvn install

cd 'spring-cloud-gateway-server/target/'
java -jar -Dserver.port=8080 'spring-cloud-gateway-server-0.0.1-SNAPSHOT.jar'
