#!/bin/sh

### These are the variables a profile can set:
###   - PROFILE_NAME       (required) -> name of the profile
###   - PROFILE_MODULES    (required) -> list of all available modules
###   - PKGS_LIST          (optional) -> list of all packages to be processed for (un)install
###   - SRC_DEST           (optional) -> path to source of module folders
###   - DEST_DIR           (optional) -> directory where modules should be deployed
###   - PKG_INSTALL_FUNC   (optional) -> function used to install packages
###   - PKG_UNINSTALL_FUNC (optional) -> function used to remove packages
###
### In a profile:
###   * Use "register_module <mod>" to add a module name (string) to $PROFILE_MODULES
###   * Use "<mod>_pkgs=("<pkg1>" "<pkg2>" "<..>")


_usage() {
    cat <<EOF
USAGE: ./manage.sh <command> [<profile> <modules ...>]

<command> must be one of:
    install/uninstall, deploy/remove, list or help.

<profile> is the path to the actual profile script.

<modules> is the list of modules to be used.
NOTE: Use 'all' to select every available module.

COMMANDS:
   - install|uninstall: ./manage.sh install <profile> <modules>
   Perfom one-time actions such as creating directories, installing
   packages and modifying system-wide configuration files.
   NOTE: Often requires root privileges.

   - deploy|remove: ./manage.sh deploy <profile> <modules>
   Install or remove config files.

   - list: ./manage.sh list <profile>
   Display available modules.

   - help: ./manage.sh help
   Print this message.

EOF
}


_perform_install() {

    _echo "Ready to install: $@"
    for m in "$@" ; do
        _function_exists "install_${m}" && eval "install_${m} install"
    done

    # Install all $PKGS_LIST[@] at once
    if [ -n "$PKG_INSTALL_FUNC" ] ; then
        ${PKG_INSTALL_FUNC} "${PKGS_LIST[@]}" \
            || _die "<--> Error installing packages: ${PKGS_LIST[@]}"
        _echo "Installed following packages: ${PKGS_LIST[@]}"
    fi
    _echo && _echo "Done installing: $@" && _echo
}


_perform_uninstall() {

    _echo "Ready to uninstall: $@"

    for m in "$@" ; do
        _function_exists "install_${m}" && eval "install_${m} uninstall"
    done

    if [ -n "$PKG_UNINSTALL_FUNC" ] ; then
        $PKG_UNINSTALL_FUNC "${PKGS_LIST[@]}" > /dev/null 2>&1 \
            || _die "<--> Error uninstalling packages: ${PKGS_LIST[@]}"
        _echo "Uninstalled packages: ${PKGS_LIST[@]}"
    fi

    _echo && _echo "Done uninstalling: $@" && _echo
}


_perform_deploy() {

    _echo "Ready to deploy: $@"

    for m in "$@" ; do
        _function_exists "deploy_${m}" && eval "deploy_${m} deploy"
    done

    _echo && _echo "Done deploying: $@" && _echo
}


_perform_remove() {

    _echo "Ready to remove: $@"

    for m in "$@" ; do
        _function_exists "deploy_${m}" && eval "deploy_${m} remove"
    done

    _echo && _echo "Done removing: $@" && _echo
}


_load_profile() {
    # $1: path_to_profile

    # Declare script-wide variables
    PROFILE_NAME=""
    #declare -a PROFILE_MODULES
    PROFILE_MODULES=()
    PKGS_LIST=()
    LOG_MSGS=()
    # ksh: declare -a ok ???
    # set -A PROFILE_MODULES
    # set -A PKGS_LIST
    # set -A LOG_MSGS

    # Get full path to this script and use it as default SRC_DIR
    SRC_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )" #dirty
    export SRC_DIR

    # Get username and set default DEST_DIR to /root or /home/user
    USER_NAME_TMP="$(whoami)"
    if [ "${USER_NAME_TMP}" = "root" ] ; then
        DEST_DIR="/root"
    elif [ -d "/home/${USER_NAME_TMP}" ] ; then
        DEST_DIR="/home/${USER_NAME_TMP}"
    else
        _die "<--Error--> Incorrect user (whoami): ${USER_NAME_TMP}"
    fi
    export DEST_DIR

    # Source and check profile
    [ ! -f "$1" ]                    && _die "<--Error--> Invalid profile file: $1 \\n"
    . "$1"
    [ -z "${PROFILE_NAME}" ]         && _die "<--Error--> Incorrect PROFILE_NAME in $1"
    [ ${#PROFILE_MODULES[*]} -eq 0 ] && _die "<--Error--> Incorrect PROFILE_MODULES in $1"
}


_check_modules() {

    if [ "$1" = "all" ] ; then
        MODULES_TO_PROCESS=${PROFILE_MODULES[@]}
    else
        MODULES_TO_PROCESS=()
        for m in "$@" ; do
            for p in "${PROFILE_MODULES[@]}" ; do
                if [ "$m" = "$p" ] ; then
                    MODULES_TO_PROCESS[${#MODULES_TO_PROCESS[*]}]=${m}
                fi
            done
        done
    fi
}


_list_modules() {

    _echo "Available modules in ${PROFILE_NAME}:"

    for m in "${PROFILE_MODULES[@]}"; do
        isInstall=$( _function_exists "install_${m}"; echo $? )
        isDeploy=$( _function_exists "deploy_${m}" ; echo $? )
        availModes="err"

        if [ "${isInstall}" -eq 0 ]; then
            availModes="install"
            if [ "${isDeploy}" -eq 0 ]; then
                availModes="install/deploy"
            fi
        elif [ "${isDeploy}" -eq 0 ]; then
            availModes="deploy"
        fi
        _echo "  - ${m} (${availModes})"

    done
    _echo
}


_show_logs() {

    if [ ! ${#LOG_MSGS[*]} -eq 0 ] ; then
        _echo && _echo "*** Additional messages ***"
        for l in "${LOG_MSGS[@]}" ; do
            [ -n "$l" ] && _echo "  - $l"
        done
        _echo
    fi
}


### Utility functions
### (can be used in profiles)

_echo() {
    if [ "$#" -gt 0 ]; then
        printf %s "$1"
        shift
    fi
    if [ "$#" -gt 0 ]; then
        printf ' %s' "$@"
    fi
    printf '\n'
}

_echo_n() {
    if [ "$#" -gt 0 ]; then
        printf %s "$1"
        shift
    fi
    if [ "$#" -gt 0 ]; then
        printf ' %s' "$@"
    fi
}

_echo_e() {
    if [ "$#" -gt 0 ]; then
        printf %b "$1"
        shift
    fi
    if [ "$#" -gt 0 ]; then
        printf ' %b' "$@"
    fi
    printf '\n'
}


_die() { _echo "$1" ; exit 1; }


_function_exists() {
    LC_ALL=C [ "$(type -t $1)" == 'function' ]
}


_register_module() {
    PROFILE_MODULES+=("$1")
}

_add_to_pkgs() {
    # $@ : list of packages to add
    for i in "$@"; do
        PKGS_LIST[${#PKGS_LIST[*]}]="$i"
    done
}


_log_msg() {
    # $1 : string to be added to the log list
    LOG_MSGS[${#LOG_MSGS[*]}]="$1"
}


_replace_tag() {
    # $1: source file
    # $2: tag
    # $3: replacement

    # Escaping replacement for sed, ex: /home/foo => \/home\/foo
    ESCAPED_TMP="$( echo "$3" | sed 's=/=\\/=g' )"
    # Replace tag and write into .tmp file
    sed -i "s/${2}/${ESCAPED_TMP}/g" "$1"
}


_rm() {
    for i in "$@"; do
        rm -rf "$i"
    done
}


_add_cronjob() {
    # $1 : cronjob formatted string

    if [ -n "$1" ] ; then
        # crontab -l outputs on stderr if empty, we ignore the err msg,
        # add our entry and pipe through sort|uniq to get rid of duplicates
        crontab -l 2> /dev/null | { cat; echo "$1"; } | sort | uniq | crontab -
    fi
}


_del_cronjob() {
    # $1: string to match crontab entries to be deleted

    if [ -n "$1" ]; then
        crontab -l 2> /dev/null | grep -v "$1" | crontab -
    fi
}



### Main -- Process command-line arguments
###
### $1 : command         (required)
### $2 : path/to/profile (opt)
### $@ : modules         (opt)

[ $# = 0 ] && _usage && exit 0
case "$1" in

    "list") # ./manage.sh list <profile>

        _load_profile "$2"
        shift; shift
        _list_modules
        exit 0
        ;;

    "install" | "uninstall" | "deploy" | "remove") # ./manage.sh install/uninstall <profile> <modules..>

        MODE_TMP="$1"
        _load_profile "$2"
        shift; shift

        if _function_exists "_perform_${MODE_TMP}"; then
            _check_modules "$@"
            eval "_perform_${MODE_TMP} ${MODULES_TO_PROCESS[@]}"
            _show_logs
        else
            _die "<--Error--> _perform_${MODE_TMP} not implemented"
        fi
        exit 0
        ;;

    "help") # ./manage.sh help
        _usage
        exit 0
        ;;

    *) # Invalid option, quit quit quit!
        _echo "<--Error--> Invalid command: $1" && _echo
        _usage
        exit 1
        ;;
esac
