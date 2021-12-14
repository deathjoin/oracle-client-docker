# oracle-client-docker
Installing Oracle client ver 19.03 with patch to 19.11 in CentOS based distro via multistage.

## Files needed
* `oracle-files/LINUX.X64_193000_client.zip` - Oracle client 19.03
* `oracle-files/p6880880_190000_Linux-x86-64.zip` - Patcher update
* `oracle-files/p32545013_190000_Linux-x86-64.zip` - Patch to 19.11

## Build args
* `REPOSITORY` - base image registry. Defaults to `registry:5000`
* `IMAGE` — base image. Defaults to `redos`
* `VERSION` — base image tag. Defaults to `7.2`

Another arguments you can change, but change files in `oracle-config` first:
* `ORACLE_HOME` - path where oracle-client will be installed `/app/product/u02/app/oracle/product/19.3/client_1`
* `ORACLE_ROOT` - oracle root `/app/product/u02`
* `TMPDIR` — Temporary files for installation `tmp-files`
* `JAVA_HOME` — path to java `/usr/lib/jvm/java-1.8.0-openjdk`

## Additional info
`tsnames.ora` contains test data.

`apline:3.14` image will be used to unpack archives.