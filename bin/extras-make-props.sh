#!/bin/bash
TOOL_NAME=$(basename $0)
INSTANCE_BIN=$(cd `dirname $0`;pwd)
INSTANCE_HOME=$(cd ${INSTANCE_BIN}/..;pwd)
INSTANCE_CONF="${INSTANCE_HOME}/config"
INSTANCE_PROPS="${INSTANCE_CONF}/tools.properties"

# source instance environment variables
test -f ${INSTANCE_HOME} && . ${INSTANCE_HOME}/extra-env

usage ()
{
echo <<END_USAGE
Usage: ${TOOL_NAME} {options}
    where {options} include:

    -I, --adminUID
            User ID of the global administrator used to bind to the server.  If
        the admin UID is not specified, the replication properties will not be
        generated in the target properties file
    --adminPassword
        The global administrator password
    --adminPasswordFile
        The file containing the password of the global administrator
    -c, --clear
        Clear the contents of the target properties file first
    -D, --bindDN
        DN used to bind to the server
    -h, --hostname
        Directory Server hostname or IP address
    --help
        Display general usage information
    -j, --bindPasswordFile
        Bind password file
    -o, --output
        The file to write properties to
    -p, --port
        Server port number
    -P, --trustStorePath
        Certificate truststore path
    -q, --useStartTLS
        Use StartTLS to secure communication with the server
    --useNoSecurity
        Use in-the-clear communication with the server
    -w, --bindPassword
        Password used to bind to the server
    -X, --trustAll
        Trust all server SSL certificates
    -Z, --useSSL
        Use SSL for secure communication with the server
END_USAGE
exit 99
}

#
# Initialize variables
#

# the main user DN default value should be directory manager for consistency with other tools
mainUserDN="cn=Directory Manager"
mainUserPassword=""
mainUserPasswordFile=""

# the replication user defaults to empty because not all products need to have replication tool properties and we user
# the user as empty to indicate replication properties are not to be generated
replicationUser=""
replicationUserPassword=""
replicationUserPasswordFile=""

# hostname defaults to localhost for consistency
hostname="localhost"

# port defaults to LDAP standard port is
port="389"

# use no security by default for consistency as well
useNoSecurity=1
userStartTLS=0
useSSL=0
trustStorePath=""
# clearProperties is set to which means that the generated options will be appended to the tools.properties file
clearPropertiesFile=0

# if no option is provided with a custom properties file path then the default is the one of the instance
props="${INSTANCE_PROPS}"

# trustAll defaults to false since by default there is no TLS at all
trustAll=0


while ! test -z "${1}" ; do
    case "${1}" in
        --adminPassword)
            shift
            if ! test -z "${1}" ; then
                echo "You must provide a value after the --adminPassword option"
                usage
            fi
            adminPassword="${1}"
            ;;
        --adminPasswordFile)
            shift
            if test -z "${1}" ; then
                echo "You must provide a value after --adminPasswordFile"
                usage
            fi
            if ! test -f "${1}" ; then
                echo "Admin password file not found: "$1
                usage
            fi
            adminPasswordFile="${1}"
            ;;
        -c|--clear)
            clearPropertiesFile=1
            ;;
        -D|--bindDN)
            shift
            if test -z "${1}" ; then
                echo "You must provide a DN after the bindDN option"
                usage
            fi
            mainUserDN="${1}"
            ;;
        -h|--hostname)
            shift
            if test -z "${1}" ; then
                echo "You must provide a hostname after the --hostname option"
                usage
            fi
            hostname="${1}"
            ;;
        --help)
            usage
            ;;
        -I|--adminUID)
            shift
            if test -z "${1}" ; then
                echo "You must provide a replication admin UID after the --adminUID option"
                usage
            fi
            replicationUser="${1}"
            ;;
        -j|--bindPasswordFile)
            shift
            if ! test -f "${1}" ; then
                echo "Bind password file not found: "$1
                usage
            fi
            mainUserPasswordFile="${1}"
            ;;
        -o|--output)
            shift
            if test -z "${1}" ; then
                echo "You must provide a file path after the output option"
                usage
            fi
            props="${1}"
            ;;
        -p|--port)
            shift
            if test -z "${1}" ; then
                echo "You must provide a port number after the port option"
                usage
            fi
            port=${1}
            ;;
         -P|--trustStorePath)
            shift
            if test -z "${1}" ; then
                echo "You must provide a file path after the trustStorePath option"
                usage
            fi
            if ! test -f "${1}" ; then
                echo "Trust store file not found: "$1
                usage
            fi
                trustStorePath="${1}"
            ;;
        -q|--useStartTLS)
            useSSL=0
            useNoSecurity=0
            useStartTLS=1
            ;;
        --useNoSecurity)
            useSSL=0
            useNoSecurity=1
            useStartTLS=0
            ;;
        -w|--bindPassword)
            shift
            if test -z "${1}" ; then
                echo "You must provide a DN after the bindPassword option"
                usage
            fi
            mainUserPassword="${1}"
            ;;
        -X|--trustAll)
            trustAll=1
            ;;
        -Z|--useSSL)
            useSSL=1
            useNoSecurity=0
            useStartTLS=0
            ;;
    esac
    shift
done

# Sanity check

# 1 - password and password file cannot be specified at the same time
if ! test -z "${mainUserPassword}" && ! test -z "${mainUserPasswordFile}" ; then
    echo "The --bindPassword and --bindPasswordFile options are mutually exclusive"
    usage
fi

# 2  - either password or password file must be provided to authenticate successfully
if test -z "${mainUserPassword}" && test -z "${mainUserPasswordFile}" ; then
    echo "One of --bindPassword or --bindPasswordFile options must be provided"
    usage
fi

# 3 - trustStorePath and trustAll are mutually exclusive as well
if ! test  ${trustAll} -ne 0 && ! test -z "${trustStorePath}" ; then
    echo "The --trustAll and --trustStorePath options are mutually exclusive"
    usage
fi

# 4 - trustStorePath or trustAll must be provided if the authentication use TLS or StartTLS
if test ${trustAll} -eq 0 && test -z "${trustStorePath}" && test ${useNoSecurity} -eq 0 ; then
  echo "Either --trustAll or --trustStorePath must be specified if TLS is to be used"
  usage
fi

# 5 - password and password file cannot be specified at the same time
if ! test -z "${replicationUserPassword}" && ! test -z "${replicationUserPasswordFile}" ; then
    echo "The --adminPassword and --adminPasswordFile options are mutually exclusive"
    usage
fi

# 6  - either password or password file must be provided to authenticate successfully
if test -z "${replicationUserPassword}" && test -z "${replicationUserPasswordFile}" && ! test -z "${replicationUser}"; then
    echo "One of --adminPassword or --adminPasswordFile options must be provided"
    usage
fi

# Wipe the properties file if the clear option was provided
if test ${clearPropertiesFile} -eq 1 ; then
    echo > ${props}
fi

# check for a previous marker of this tool execution in the destination properties file
grep -c "^#MAKE-PROPS" ${props} >/dev/null && exit 77

# explicit list of tools that are exceuted as tasks
tasks="audit-data-security backup collect-support-data export-ldif import-ldif rebuild-index"

for command in  audit-data-security backup collect-support-data dsconfig dsframework dsreplication dump-dns enter-lockdown-mode export-ldif generate-totp-shared-secret identify-references-to-missing-entries identify-unique-attribute-conflicts import-ldif ldapcompare ldapdelete ldapmodify ldapsearch leave-lockdown-mode manage-account manage-tasks monitored-servers parallel-update rebuild-index status subtree-accessibility ; do
    if test "${command}" = "dsreplication" && ! test -z "${replicationUser}"; then
        echo ${command}.adminUID=${replicationUser}                             >> ${props}
        if test -z "${replicationUserPasswordFile}" ; then
            echo ${command}.adminPassword=${replicationUserPassword}            >> ${props}
        else
            echo ${command}.adminPasswordFile=${replicationUserPasswordFile}    >> ${props}
        fi
    else
        echo ${command}.bindDN=${mainUserDN}                                    >> ${props}
        if test -z "${mainUserPasswordFile}" ; then
            echo ${command}.bindPassword=${mainUserPassword}                    >> ${props}
        else
            echo ${command}.bindPasswordFile=${mainUserPasswordFile}            >> ${props}
        fi
    fi
    echo ${command}.hostname=${hostname}                                        >> ${props}
    echo ${command}.port=${port}                                                >> ${props}

    if test ${useNoSecurity} -eq 0 ; then
        if test ${useSSL} -eq 1 ; then
            echo ${command}.useSSL=true                                         >> ${props}
        else
            echo ${command}.useStartTLS=true                                    >> ${props}
        fi
        if ! test -z "${trustStorePath}" ; then
            echo ${command}.trustStorePath=${HOME}/.staging/truststore          >> ${props}
        else
            echo ${command}.trustAll=ture                                       >> ${props}
        fi
    fi

    case ${tasks} in  *"${command}"*)
        echo ${command}.task=true                                               >> ${props}
        echo ${command}.start=0                                                 >> ${props}
        ;;
    esac
    if test "${command}" = "status" ; then
        echo ${command}.maxAlerts=3                                             >> ${props}
        echo ${command}.alertSeverity=error                                     >> ${props}
        echo ${command}.alarmSeverity=major                                     >> ${props}
    fi
    if test "${command}" = "ldapsearch" ; then
        echo ${command}.dontWrap=true                                           >> ${props}
    fi
  echo
done
echo "#MAKE-PROPS" 					                        >> ${props}
echo "Processing complete."