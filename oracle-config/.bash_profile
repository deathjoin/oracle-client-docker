# .bash_profile

# Get the aliases and functions
if [ -f ~/.bashrc ]; then
        . ~/.bashrc
fi

# User specific environment and startup programs

PATH=$PATH:$HOME/.local/bin:$HOME/bin

export PATH

LANG=ru_RU.CP1251; export LANG

export ORACLE_HOME=/app/product/u02/app/oracle/product/19.3/client_1
export LD_LIBRARY_PATH=$ORACLE_HOME/lib:/usr/lib
export PATH=$PATH:$ORACLE_HOME/bin
export TNS_ADMIN=$ORACLE_HOME/network/admin
export ORACLE_TERM=xterm
export TMP=/tmp
export TMPDIR=$TMP