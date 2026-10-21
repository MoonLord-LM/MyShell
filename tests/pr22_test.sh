#!/bin/bash

# Focused unit tests for PR #22. Run manually with: bash tests/pr22_test.sh
# Uses Bash and standard Debian/Ubuntu utilities, with no installation or network.
set -o pipefail

repo_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd) || exit 1
test_root=$(mktemp -d) || exit 1
trap 'rm -rf -- "$test_root"' EXIT
test_count=0
failure_count=0

function assert_equal(){
    if [ "$1" != "$2" ]; then
        printf 'Expected <%s>, got <%s>\n' "$2" "$1" >&2
        return 1
    fi
}

function run_test(){
    local name="$1"
    shift
    test_count=$((test_count + 1))
    # Each case gets fresh functions, variables, and shell options. Do not put
    # this subshell in an if/|| expression: that would disable errexit inside it.
    (
        trap - EXIT
        set -e
        "$@"
    )
    local status=$?
    if [ "$status" -eq 0 ]; then
        printf 'ok %s - %s\n' "$test_count" "$name"
    else
        printf 'not ok %s - %s\n' "$test_count" "$name"
        failure_count=$((failure_count + 1))
    fi
}

function command_case(){
    local cmd="$1" resolved="$2" lookup_status="$3"
    local package="$4" package_status="$5" expected="$6" expected_status="$7"
    local calls="$test_root/command-calls" errors="$test_root/command-errors"
    local output status=0
    rm -f "$calls"
    source "$repo_root/bash/My.sh" 2>/dev/null

    # Mock only external lookups; retain the real validation and logging code.
    function command(){
        assert_equal "$#" '2' || return 1
        assert_equal "$1" '-v' || return 1
        assert_equal "$2" "$cmd" || return 1
        printf 'lookup\n' >> "$calls"
        [ "$lookup_status" -eq 0 ] || return "$lookup_status"
        printf '%s\n' "$resolved"
    }
    function dpkg(){
        assert_equal "$#" '2' || return 1
        assert_equal "$1" '-S' || return 1
        assert_equal "$2" "$resolved" || return 1
        printf 'package\n' >> "$calls"
        printf '%s' "$package"
        printf 'package lookup diagnostic\n' >&2
        return "$package_status"
    }

    output=$(check_command_exist "$cmd" 2>"$errors") || status=$?
    assert_equal "$status" "$expected_status"
    assert_equal "$output" ''
    assert_equal "$(cat "$errors")" "$expected"
    if [ "$cmd" == '' ]; then
        [ ! -e "$calls" ]
    elif [ "$lookup_status" -ne 0 ]; then
        assert_equal "$(cat "$calls")" 'lookup'
    else
        assert_equal "$(cat "$calls")" $'lookup\nlookup\npackage'
    fi
}

function load_frp_config(){
    local config
    # The Config section has no installation side effects. Fail closed if the
    # boundary disappears instead of sourcing the installer or downloading My.sh.
    config=$(awk '
        /^# .* Init .*$/ { found=1; exit }
        { print }
        END { if (!found) exit 1 }
    ' "$repo_root/bash/docker/frp.sh")
    eval "$config"
}

function frp_case(){
    local token_mode="$1" password_mode="$2" expected_draws="$3"
    local entropy_calls="$test_root/entropy-calls"
    local server_config client_config draws=0 decoded
    rm -f "$entropy_calls"
    unset FRP_TOKEN FRP_DASHBOARD_PASSWORD
    case "$token_mode" in
        empty) export FRP_TOKEN='' ;;
        supplied) export FRP_TOKEN='preset-token' ;;
        special) export FRP_TOKEN='  tok\"en $HOME `id` ; *  ' ;;
    esac
    case "$password_mode" in
        empty) export FRP_DASHBOARD_PASSWORD='' ;;
        supplied) export FRP_DASHBOARD_PASSWORD='preset-password' ;;
        special) export FRP_DASHBOARD_PASSWORD='  pass\"word $HOME `id` ; *  ' ;;
    esac

    # Supply deterministic 32-byte entropy, distinct for each draw. The real
    # base64 and sed still run, and the requested byte count/device are checked.
    function head(){
        assert_equal "$#" '3' || return 1
        assert_equal "$1" '-c' || return 1
        assert_equal "$2" '32' || return 1
        assert_equal "$3" '/dev/urandom' || return 1
        if [ -e "$entropy_calls" ]; then
            printf '%032d' 2
        else
            printf '%032d' 1
        fi
        printf 'draw\n' >> "$entropy_calls"
    }

    load_frp_config
    if [ -e "$entropy_calls" ]; then
        draws=$(wc -l < "$entropy_calls")
        draws=$((draws))
    fi
    assert_equal "$draws" "$expected_draws"

    if [ "$token_mode" == 'supplied' ] || [ "$token_mode" == 'special' ]; then
        assert_equal "$frp_token" "$FRP_TOKEN"
    else
        [[ "$frp_token" =~ ^[A-Za-z0-9+/]{43}=$ ]]
        decoded=$(printf '%s' "$frp_token" | base64 -d)
        assert_equal "$decoded" '00000000000000000000000000000001'
    fi
    if [ "$password_mode" == 'supplied' ] || [ "$password_mode" == 'special' ]; then
        assert_equal "$frp_dashboard_password" "$FRP_DASHBOARD_PASSWORD"
    else
        [[ "$frp_dashboard_password" =~ ^[A-Za-z0-9+/]{43}=$ ]]
        decoded=$(printf '%s' "$frp_dashboard_password" | base64 -d)
        if [ "$expected_draws" -eq 2 ]; then
            assert_equal "$decoded" '00000000000000000000000000000002'
        else
            assert_equal "$decoded" '00000000000000000000000000000001'
        fi
    fi

    frp_server_ip='192.0.2.1'
    server_config=$(generate_frp_server_config)
    client_config=$(generate_frp_client_demo_config)
    local expected_token="$frp_token" expected_password="$frp_dashboard_password"
    if [ "$token_mode" == 'special' ]; then
        expected_token='  tok\\\"en $HOME `id` ; *  '
    fi
    if [ "$password_mode" == 'special' ]; then
        expected_password='  pass\\\"word $HOME `id` ; *  '
    fi
    assert_equal "$(printf '%s\n' "$server_config" | grep '^auth.token = ')" \
        "auth.token = \"${expected_token}\""
    assert_equal "$(printf '%s\n' "$client_config" | grep '^auth.token = ')" \
        "auth.token = \"${expected_token}\""
    assert_equal "$(printf '%s\n' "$server_config" | grep '^webServer.password = ')" \
        "webServer.password = \"${expected_password}\""
}

function cockpit_case(){
    local mode="$1" statement target status=0
    local sandbox="$test_root/cockpit sandbox"
    rm -rf -- "$sandbox"
    mkdir -p "$sandbox"
    target="$sandbox/disallowed-users"
    # Execute the changed operation only. Redirect its fixed system path into
    # the fixture without changing the command or touching the host's /etc.
    statement=$(awk '
        $1 == "echo" && $2 == ">" && index($0, "/etc/cockpit/disallowed-users") {
            print; count++
        }
        END { if (count != 1) exit 1 }
    ' "$repo_root/bash/install/cockpit.sh")
    statement=${statement//\/etc\/cockpit\/disallowed-users/$target}
    case "$mode" in
        existing|repeat) printf 'root\nadmin\nother-user\n' > "$target" ;;
        directory) mkdir "$target" ;;
        missing_parent) rmdir "$sandbox" ;;
    esac
    bash -c "$statement" >"$test_root/cockpit-output" 2>"$test_root/cockpit-errors" || status=$?
    assert_equal "$(cat "$test_root/cockpit-output")" ''
    if [ "$mode" == 'directory' ] || [ "$mode" == 'missing_parent' ]; then
        [ "$status" -ne 0 ]
        [ -s "$test_root/cockpit-errors" ]
        if [ "$mode" == 'directory' ]; then
            [ -d "$target" ]
        else
            [ ! -e "$sandbox" ]
        fi
    else
        assert_equal "$status" '0'
        [ ! -s "$test_root/cockpit-errors" ]
        [ -f "$target" ]
        printf '\n' > "$test_root/expected-disallowed-users"
        cmp "$test_root/expected-disallowed-users" "$target"
        if [ "$mode" == 'repeat' ]; then
            bash -c "$statement"
            cmp "$test_root/expected-disallowed-users" "$target"
        fi
    fi
}

run_test 'command reports its owning package' command_case \
    fixture '/usr/bin/fixture' 0 'fixture-pkg: /usr/bin/fixture' 0 \
    'check_command_exist: "fixture" exists in "fixture-pkg: /usr/bin/fixture"' 0
run_test 'unowned command reports its path and suppresses dpkg errors' command_case \
    fixture '/opt/custom bin/fixture' 0 '' 1 \
    'check_command_exist: "fixture" exists in "/opt/custom bin/fixture"' 0
run_test 'empty package result falls back to command path' command_case \
    fixture '/usr/local/bin/fixture' 0 '' 0 \
    'check_command_exist: "fixture" exists in "/usr/local/bin/fixture"' 0
run_test 'missing dpkg does not hide an existing command' command_case \
    fixture '/usr/local/bin/fixture' 0 '' 127 \
    'check_command_exist: "fixture" exists in "/usr/local/bin/fixture"' 0
run_test 'shell builtin has no owning package' command_case \
    printf 'printf' 0 '' 1 'check_command_exist: "printf" exists in "printf"' 0
run_test 'missing command fails without a package lookup' command_case \
    fixture '' 1 '' 0 'check_command_exist: "fixture" does not exist' 1
run_test 'empty command fails before any lookup' command_case \
    '' '' 0 '' 0 'check_command_exist: parameter [ 1 ] is empty' 1

run_test 'unset FRP credentials use separate 32-byte draws' frp_case unset unset 2
run_test 'empty FRP credentials use defaults' frp_case empty empty 2
run_test 'supplied token only generates dashboard password' frp_case supplied unset 1
run_test 'supplied password only generates token' frp_case unset supplied 1
run_test 'supplied token and empty password default independently' frp_case supplied empty 1
run_test 'empty token and supplied password default independently' frp_case empty supplied 1
run_test 'supplied FRP credentials skip entropy generation' frp_case supplied supplied 0
run_test 'FRP credentials preserve spaces and escape quotes and backslashes' frp_case special special 0

run_test 'Cockpit creates the disallowed-users file with one newline' cockpit_case absent
run_test 'Cockpit removes all existing disallowed users' cockpit_case existing
run_test 'Cockpit clearing is idempotent' cockpit_case repeat
run_test 'Cockpit clearing fails when the target is a directory' cockpit_case directory
run_test 'Cockpit clearing fails when the parent is missing' cockpit_case missing_parent

printf '1..%s\n' "$test_count"
[ "$failure_count" -eq 0 ]
