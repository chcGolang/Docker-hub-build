#!/bin/sh
set -eu

cd /base

CONF=""
if [ -f pref.toml ]; then
    CONF=pref.toml
elif [ -f pref.yml ]; then
    CONF=pref.yml
elif [ -f pref.ini ]; then
    CONF=pref.ini
fi

if [ -z "$CONF" ]; then
    cp pref.example.ini pref.ini
    CONF=pref.ini
fi

if [ "$CONF" != "pref.ini" ]; then
    echo "[entrypoint] using $CONF, SC_* env overrides are ignored (remove pref.toml/pref.yml to use pref.ini)" >&2
    exec "$@"
fi

set_ini() {
    section="$1"
    key="$2"
    VALUE="$3" awk -v sec="$section" -v key="$key" '
    BEGIN {
        target = "[" sec "]"
        replaced = 0
        insection = 0
        foundsection = 0
        value = ENVIRON["VALUE"]
    }
    /^\[/ {
        if (insection && !replaced) {
            print key "=" value
            replaced = 1
        }
        insection = ($0 == target)
        if (insection) foundsection = 1
        print
        next
    }
    insection && !replaced {
        line = $0
        sub(/^[;]?[ \t]*/, "", line)
        if (index(line, "=")) {
            k = substr(line, 1, index(line, "=") - 1)
            sub(/[ \t]*$/, "", k)
            if (k == key) {
                print key "=" value
                replaced = 1
                next
            }
        }
    }
    {
        print
    }
    END {
        if (!replaced) {
            if (foundsection) {
                print key "=" value
            } else {
                print target
                print key "=" value
            }
        }
    }
    ' pref.ini > pref.ini.tmp && mv pref.ini.tmp pref.ini
}

apply() {
    section="$1"
    key="$2"
    var="$3"
    value="$(printenv "$var" 2>/dev/null || true)"
    [ -n "$value" ] || return 0
    set_ini "$section" "$key" "$value"
    echo "[entrypoint] $var -> [$section] $key=$value"
}

apply common api_mode SC_API_MODE
apply common api_access_token SC_API_ACCESS_TOKEN
apply common default_url SC_DEFAULT_URL
apply common insert_url SC_INSERT_URL
apply common enable_insert SC_ENABLE_INSERT
apply common exclude_remarks SC_EXCLUDE_REMARKS
apply common include_remarks SC_INCLUDE_REMARKS
apply common proxy_config SC_PROXY_CONFIG
apply common proxy_ruleset SC_PROXY_RULESET
apply common proxy_subscription SC_PROXY_SUBSCRIPTION
apply common reload_conf_on_request SC_RELOAD_CONF_ON_REQUEST
apply managed_config managed_config_prefix SC_MANAGED_CONFIG_PREFIX
apply managed_config config_update_interval SC_CONFIG_UPDATE_INTERVAL
apply managed_config config_update_strict SC_CONFIG_UPDATE_STRICT
apply server listen SC_LISTEN
apply server port SC_PORT
apply advanced log_level SC_LOG_LEVEL
apply advanced enable_cache SC_ENABLE_CACHE
apply advanced cache_subscription SC_CACHE_SUBSCRIPTION
apply template clash.http_port SC_CLASH_HTTP_PORT
apply template clash.socks_port SC_CLASH_SOCKS_PORT
apply template clash.allow_lan SC_CLASH_ALLOW_LAN
apply template clash.external_controller SC_CLASH_EXTERNAL_CONTROLLER
apply template singbox.mixed_port SC_SINGBOX_MIXED_PORT
apply template singbox.allow_lan SC_SINGBOX_ALLOW_LAN
apply emojis add_emoji SC_ADD_EMOJI
apply emojis remove_old_emoji SC_REMOVE_OLD_EMOJI

exec "$@"
