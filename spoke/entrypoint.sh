#!/bin/bash
set -e

# Tunable settings
WHEEL_NAME=${WHEEL_NAME:-$(echo "wheel-$(date | md5sum | head -c6)")}
SERVER_LISTEN_ADDRESS=${SERVER_LISTEN_ADDRESS:-"0.0.0.0"}
SERVER_LISTEN_PORT=${SERVER_LISTEN_PORT:-"28777"}
SERVER_ADDRESS=${SERVER_ADDRESS:-"0.0.0.0"}
WEB_PORT=${WEB_PORT:-"28778"}
DELAY=${DELAY:-5}
# Mode options: {server|harvester|default}
MODE=${MODE:-"default"}

# Misc settings
ERR_LOG=/log/$HOSTNAME/logio_stderr.log

# log.io is surprisingly lacking in command line options (they have none) and
# all logs need to be explicitely listed in the harvester.conf (which is
# antithetical to how radial works). Thus, this circus needs to happen.

t="    "
pre="exports.config = {"
server_conf="\n${t}${t}host: '${SERVER_LISTEN_ADDRESS}',\n${t}${t}port: ${SERVER_LISTEN_PORT}\n${t}"
w_server_conf="\n${t}${t}host: '${SERVER_ADDRESS}',\n${t}${t}port: ${SERVER_LISTEN_PORT}\n${t}"
s_conf_wrapper="\n${t}server: {${server_conf}},\n"
w_conf_wrapper="\n${t}server: {${w_server_conf}},\n"

create_harvester_conf() {
    for nodeName in $(ls /log); do
        appName=$(find /log/$nodeName -type f -not -name "supervisord.log" -not -name "sshd*" | head -1 | awk -F "/" '{print $4}' | awk -F "_" '{print $1}')
        for logFile in $(ls /log/${nodeName}); do
            appLogs=$(printf "$appLogs,\n${t}${t}${t}${t}${t}\"/log/$nodeName/$logFile\"")
        done
        nodeLogs=$(printf "$appLogs" | sed 's/^.//')
        nodeStream=$(printf "\"$appName\": [$nodeLogs\n${t}${t}${t}]")
        allStreams=$(printf "${allStreams},\n${t}${t}${t}${nodeStream}")
        appLogs=""
    done

    allStreams=$(printf "$allStreams" | sed 's/^.//')

    nodeEntry=$(printf "${t}nodeName: \"${WHEEL_NAME}\",\n${t}${t}logStreams: {${t}${allStreams}\n${t}${t}}\n}\n")

    printf "$nodeEntry" | tee -a /root/.log.io/harvester.conf
 }

create_web_server_conf() {
    # not fully implemented.
    # TODO: dynamic HTTPS/SSL config, websocket and http restrictions
    cp -f /tmp/web_server.conf /root/.log.io/web_server.conf
    printf "\n${t}${t}host: '${SERVER_LISTEN_ADDRESS}',\n${t}${t}port: ${WEB_PORT},\n}" | tee -a /root/.log.io/web_server.conf
}

restart_message() {
    echo "Container restart on $(date)."
    echo -e "\nContainer restart on $(date)." | tee -a $ERR_LOG
}

launch() {
    case "$1" in
        server)
            if [ "$MODE" = "harvester" ]; then
                exit 0
            else
                printf "" > /root/.log.io/log_server.conf
                create_web_server_conf
                confStr="${pre}${server_conf}}"
                printf "$confStr" | tee -a /root/.log.io/log_server.conf
                exec /usr/local/bin/log.io-server | tee -a $ERR_LOG
            fi
            ;;
        harvester)
            if [ "$MODE" = "server" ]; then
                exit 0
            else
                printf "" > /root/.log.io/harvester.conf
                confStr="${pre}${w_conf_wrapper}"
                printf "$confStr" | tee -a /root/.log.io/harvester.conf
                sleep ${DELAY}s && create_harvester_conf
                exec /usr/local/bin/log.io-harvester | tee -a $ERR_LOG
            fi
            ;;
        *)
            exit 1
            ;;
    esac
}

if [ ! -e /tmp/logio_${1}_first_run ]; then
    touch /tmp/logio_${1}_first_run
    launch "$1"
else
    restart_message
    launch "$1"
fi
