# ── Deployment & Build ─────────────────────────────────────────
alias dev_deploy="bazel run //services/deploy:dev_deploy"
alias deploy_auth="bazel run //services/auth/central/server:kubecfg"
alias deploy_billing="bazel run //services/billing/central:kubecfg"
alias deploy_metering="bazel run //services/billing/metering:kubecfg"
alias deploy_rollup="bazel run //services/billing/rollup:kubecfg"
alias deploy_customer="bazel run //services/customer/frontend:kubecfg"
alias deploy_web="bazel run //services/web_rpc_proxy:kubecfg"
alias format="bazel run //:format"
alias b="bazel"

# ── Development Utilities ──────────────────────────────────────
check_tombstone() {
    if [[ -z "$1" ]]; then echo "Usage: check_tombstone <target-name>"; return 1; fi
    bazel run //tools/deploy_runner:check_tombstone -- --target-name="$1"
}

fake_ff() {
    if [[ -z "$1" || -z "$2" ]]; then
        echo "Usage: fake_ff <flag-key> <json-value>"
        echo 'Example: fake_ff "my_feature" '"'"'{"enabled": true}'"'"''
        return 1
    fi
    bazel run //services/test/fake_feature_flags:util -- update --key "$1" --json "$2"
}

# ── Protocol Buffer Stubs ─────────────────────────────────────
alias stubs="bazel run //tools/generate_proto_typestubs"
alias stubs_ts="bazel run //tools/generate_proto_typestubs:generate_ts_proto_typestubs"

stubs_go() {
    if [[ -z "$1" ]]; then echo "Usage: stubs_go <proto-path>"; return 1; fi
    bazel run //tools/generate_proto_typestubs:go -- "$1"
}
