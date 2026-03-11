#!/bin/bash

# ==============================================================================
# JEHAD BEAST - CLOUDFLARE API CORE MODULE
# ==============================================================================
# Advanced Cloudflare API integration with error handling, retry logic,
# and record synchronization.
# ==============================================================================

CF_Token="qnN2p02BHhqOulA9xugCaAi33ZQr_GSRAUL0uloS"
CF_ZoneID="7917ca1fa4bf3efa766230e55b820e8a"
CF_BASE_URL="https://api.cloudflare.com/client/v4"

# --- [ API CALL WRAPPER ] ---
cf_request() {
    local method=$1
    local endpoint=$2
    local data=$3
    local retry_count=0
    local max_retries=3
    local response=""

    while [ $retry_count -lt $max_retries ]; do
        if [[ -z "$data" ]]; then
            response=$(curl -s -X "$method" "$CF_BASE_URL/zones/$CF_ZoneID/$endpoint" \
                 -H "Authorization: Bearer $CF_Token" \
                 -H "Content-Type: application/json")
        else
            response=$(curl -s -X "$method" "$CF_BASE_URL/zones/$CF_ZoneID/$endpoint" \
                 -H "Authorization: Bearer $CF_Token" \
                 -H "Content-Type: application/json" \
                 -d "$data")
        fi

        if echo "$response" | grep -q '"success":true'; then
            echo "$response"
            return 0
        else
            log_error "CF API Error (Attempt $((retry_count+1))): $response"
            ((retry_count++))
            sleep 2
        fi
    done
    echo "$response"
    return 1
}

# --- [ DOMAIN OPERATIONS ] ---
get_zone_details() {
    cf_request "GET" "" ""
}

get_domain_name() {
    local res=$(get_zone_details)
    echo "$res" | jq -r '.result.name'
}

# --- [ DNS RECORD OPERATIONS ] ---
list_dns_records() {
    local type=$1
    local name=$2
    local endpoint="dns_records"
    [[ -n "$type" ]] && endpoint="$endpoint?type=$type"
    [[ -n "$name" ]] && endpoint="$endpoint&name=$name"
    cf_request "GET" "$endpoint" ""
}

find_record_id() {
    local type=$1
    local name=$2
    local res=$(list_dns_records "$type" "$name")
    echo "$res" | jq -r '.result[0].id // empty'
}

upsert_dns_record() {
    local type=$1
    local name=$2
    local content=$3
    local proxied=${4:-false}
    local ttl=${5:-120}
    
    local record_id=$(find_record_id "$type" "$name")
    local payload=$(jq -n \
        --arg type "$type" \
        --arg name "$name" \
        --arg content "$content" \
        --argjson ttl "$ttl" \
        --argjson proxied "$proxied" \
        '{type: $type, name: $name, content: $content, ttl: $ttl, proxied: $proxied}')

    if [[ -n "$record_id" ]]; then
        log_info "Updating $type record: $name ($record_id)"
        cf_request "PUT" "dns_records/$record_id" "$payload"
    else
        log_info "Creating $type record: $name"
        cf_request "POST" "dns_records" "$payload"
    fi
}

delete_dns_record() {
    local record_id=$1
    [[ -z "$record_id" ]] && return 0
    log_info "Deleting DNS record: $record_id"
    cf_request "DELETE" "dns_records/$record_id" ""
}

# --- [ LOGGING HELPERS ] ---
log_info() { echo "[INFO] $(date '+%Y-%m-%d %H:%M:%S') - $1" >> "/home/ubuntu/jehad_beast/ov/logs/api.log"; }
log_error() { echo "[ERROR] $(date '+%Y-%m-%d %H:%M:%S') - $1" >> "/home/ubuntu/jehad_beast/ov/logs/api.log"; }
