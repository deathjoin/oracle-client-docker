ARG REPOSITORY=registry:5000/
ARG IMAGE=redos
ARG VERSION=7.2

ARG ORACLE_HOME=/app/product/u02/app/oracle/product/19.3/client_1
ARG ORACLE_ROOT=/app/product/u02
ARG TMPDIR=/tmp-files
ARG JAVA_HOME=/usr/lib/jvm/java-1.8.0-openjdk

#>-----------------------
# UNZIP STAGE 
# unzip archives to copy them with set owner later
# refactor this & combine with oracle_installation

FROM alpine:3.14 as unpacker
RUN apk add --no-cache unzip
# copy & unzip client 19.3
COPY oracle-files/LINUX.X64_193000_client.zip .
RUN unzip -q ./LINUX.X64_193000_client.zip
# copy & unzip opatch
COPY oracle-files/p6880880_190000_Linux-x86-64.zip .
RUN unzip -q ./p6880880_190000_Linux-x86-64.zip
# copy & unzip patch to 19.11
COPY oracle-files/p32545013_190000_Linux-x86-64.zip .
RUN unzip -q ./p32545013_190000_Linux-x86-64.zip

#>-----------------------
# INSTALLATION STAGE
# copy unzipped archives from UNPACKER
# install oracle to system
# ORACLE_ROOT will be copied to resulted image

FROM ${REPOSITORY}${IMAGE}:${VERSION} as oracle_installation

# Reuse arguments on top
ARG ORACLE_HOME
ARG ORACLE_ROOT
ARG JAVA_HOME
ARG TMPDIR

# creating groups & users: oracle
RUN groupadd -g 11000 oinstall && \
    useradd -u 11000 -g oinstall oracle

# create base directories & conf time
RUN mkdir -p ${ORACLE_HOME} && \
    mkdir -p ${TMPDIR} && \
    chown -R oracle:oinstall ${TMPDIR} && \
    chown -R oracle:oinstall ${ORACLE_ROOT} && \
    mkdir -p /app/product/fio/ibs/tmp && \
    chown -R oracle:oinstall /app/product/fio && \
    mv /etc/localtime /etc/localtime.bak && \
    ln -s /usr/share/zoneinfo/Europe/Moscow /etc/localtime

# copy files & libs
COPY --chown=oracle:oinstall oracle-files/compat-libstdc++-33-3.2.3-72.el7.x86_64.rpm oracle-config/client.rsp ${TMPDIR}/
COPY --chown=oracle:oinstall --from=unpacker client ${TMPDIR}/client
COPY --chown=oracle:oinstall --from=unpacker OPatch ${TMPDIR}/OPatch
COPY --chown=oracle:oinstall --from=unpacker 32545013 ${TMPDIR}/Update

# install dependencies:
RUN yum -y makecache && \
    yum -y install libnsl.x86_64 nfs-utils sysstat binutils compat-libcap1 gcc gcc-c++ glibc glibc-devel libgcc libstdc++ libstdc++-devel libaio libaio-devel make java-1.8.0-openjdk java-1.8.0-openjdk-devel && \
    rpm -Uvh ${TMPDIR}/compat-libstdc++-33-3.2.3-72.el7.x86_64.rpm && \
    yum -y clean all

# install: oracle client
RUN runuser -l oracle -c "${TMPDIR}/client/runInstaller -silent -ignoreSysPrereqs -ignorePrereq -waitforcompletion -responseFile ${TMPDIR}/client.rsp" || true 
    # remove old opatch
RUN rm -rf ${ORACLE_HOME}/OPatch 
    # copy new opatch
RUN cp -a ${TMPDIR}/OPatch ${ORACLE_HOME}/OPatch 
    # install 19.11 patch
RUN runuser -l oracle -c "ORACLE_HOME=${ORACLE_HOME} ${ORACLE_HOME}/OPatch/opatch apply -silent ${TMPDIR}/Update"
    # remove tmp files
RUN rm -rf /tmp-files
    # try to remove OPatch/32545013 files if any
RUN rm -rf ${ORACLE_HOME}/OPatch/32545013

#### CONFIGURE ORACLE CLIENT ####
# copy tnsnames
COPY --chown=oracle:oinstall oracle-config/tnsnames.ora ${ORACLE_HOME}/network/admin/

# make symlink for changing password to work (c)
RUN ln -s ${ORACLE_HOME}/lib/libocijdbc19.so ${ORACLE_HOME}/lib/ocijdbc19.so && \
    chown -h oracle:oinstall ${ORACLE_HOME}/lib/ocijdbc19.so

# ENVS
ENV ORACLE_HOME=${ORACLE_HOME}
ENV JAVA_HOME=${JAVA_HOME}


#>-----------------------
# FINAL STAGE
# copy all files from $ORACLE_ROOT from installation_stage
# apply config to Oracle user & system
FROM ${REPOSITORY}${IMAGE}:${VERSION}

# Reuse arguments on top
ARG ORACLE_ROOT
ARG ORACLE_HOME
ARG JAVA_HOME

# creating groups & users: oracle
RUN groupadd -g 11000 oinstall && \
    useradd -u 11000 -g oinstall oracle

# create base directories & conf time
RUN mkdir -p ${ORACLE_ROOT} && \
    chown -R oracle:oinstall ${ORACLE_ROOT} && \
    mkdir -p /app/product/fio/ibs/tmp && \
    chown -R oracle:oinstall /app/product/fio && \
    mv /etc/localtime /etc/localtime.bak && \
    ln -s /usr/share/zoneinfo/Europe/Moscow /etc/localtime

COPY oracle-files/compat-libstdc++-33-3.2.3-72.el7.x86_64.rpm /tmp/

# install dependencies:
RUN yum -y makecache && \
    yum -y install libnsl.x86_64 nfs-utils sysstat binutils compat-libcap1 gcc gcc-c++ glibc glibc-devel libgcc libstdc++ libstdc++-devel libaio libaio-devel make java-1.8.0-openjdk java-1.8.0-openjdk-devel && \
    rpm -Uvh /tmp/compat-libstdc++-33-3.2.3-72.el7.x86_64.rpm && \
    yum -y clean all

# copy full oracle installation
COPY --chown=oracle:oinstall --from=oracle_installation ${ORACLE_ROOT} ${ORACLE_ROOT}

# install oraInventory
RUN ${ORACLE_ROOT}/app/oraInventory/orainstRoot.sh

# empty oratab because no database installed locally
RUN touch /etc/oratab
RUN chown oracle:oinstall /etc/oratab

# copy bash_profile
COPY --chown=oracle:oinstall oracle-config/.bash_profile /home/oracle/
RUN chmod 0600 /home/oracle/.bash_profile

# declare env files
ENV ORACLE_HOME=${ORACLE_HOME}
ENV JAVA_HOME=${JAVA_HOME}