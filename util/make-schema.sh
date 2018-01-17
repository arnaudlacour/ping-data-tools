#!/bin/bash
TOOL_NAME=$(basename $0)
INSTANCE_BIN=$(cd `dirname $0`;pwd)
INSTANCE_HOME=$(cd ${INSTANCE_BIN}/..;pwd)
INSTANCE_CONF="${INSTANCE_HOME}/config"
EXTRAS_ENV="${INSTANCE_HOME}/extras-env"

# source instance environment variables
test -f ${EXTRAS_ENV} && . ${EXTRAS_ENV}

schemaFile="/tmp/test.ldif"
begin=0
end=999
clear=0
name="test"

usage ()
{
cat <<END_USAGE
Usage: ${TOOL_NAME} {options}
    where {options} include:

    -c, --clear
        Clear the contents of the target file first (append by default)
    -n, --numAttributes
        Number of attributes
    -N, --Name
        Attribute and object class name prefix
    -o, --output
        The file to write properties to
END_USAGE
exit 99
}

while ! test -z "${1}" ; do
    case "${1}" in
        -c|--clear)
            clear=1
            ;;
        -n|--numAttributes)
            shift
            end=${1}
            ;;
        -N|--Name)
            shift
            if test -z "${1}" ; then
                echo "A name must be specified"
                usage
            fi
            name="${1}"
            ;;
        -o|--output)
            shift
            if test -z "${1}" ; then
                echo "An output file must be specified"
                usage
            fi
            schemaFile="${1}"
            ;;
    esac
    shift
done

magnitude=$( echo -n ${end} | wc -c | sed 's/^ *//')

if test ${clear} -eq 1 ; then
    echo > ${schemaFile}
fi

for i in $( seq ${begin} ${end} ); do
  printf "attributeTypes: ( ${name}%0${magnitude}d-oid NAME '${name}%0${magnitude}d' USAGE userApplications )\n" $i $i >> ${schemaFile}
done

echo "objectClasses: ( ${name}-OID NAME '${name}' AUXILIARY MAY (" >>  ${schemaFile}
for i in $( seq ${begin} ${end} ); do
  printf " ${name}%0${magnitude}d " ${i} >> ${schemaFile}
  if test ${i} -lt ${end} ; then
    printf "$" >> ${schemaFile}
  fi
done
echo ") )" >> ${schemaFile}