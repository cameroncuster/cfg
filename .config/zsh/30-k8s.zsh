# ── Kubernetes ──────────────────────────────────────────────────
source <(kubectl completion zsh)
alias k="kubectl"
alias pk="kubectl --context gke_system-services-prod_us-central1_us-central1-prod"
alias ek="kubectl --context gke_system-services-prod_europe-west4_eu-west4-prod"

alias dev_context="kubectl config use-context gke_system-services-dev_us-central1_us-central1-dev"
alias prod_context="kubectl config use-context gke_system-services-prod_us-central1_us-central1-prod"
alias eu_context="kubectl config use-context gke_system-services-prod_europe-west4_eu-west4-prod"

# ── Logging & Monitoring ───────────────────────────────────────
# parse_logs lives in the augment repo; we read it from the `main` worktree
PARSE_LOGS="$HOME/augment/main/tools/parse_logs"

logs() {
    if [[ -z "$1" ]]; then echo "Usage: logs <pod-name>"; return 1; fi
    k logs -f "$1" | "$PARSE_LOGS"
}

app_logs() {
    if [[ -z "$1" ]]; then echo "Usage: app_logs <app-name>"; return 1; fi
    k logs -fl app="$1" | "$PARSE_LOGS"
}

auth_logs() {
    k logs -fl app=auth-central -c auth-central-grpc | "$PARSE_LOGS"
}

prod_logs() {
    if [[ -z "$1" || -z "$2" ]]; then echo "Usage: prod_logs <namespace> <pod-name>"; return 1; fi
    pk -n "$1" logs -f "$2" | "$PARSE_LOGS"
}

prod_auth_logs() {
    if [[ -z "$1" || -z "$2" ]]; then echo "Usage: prod_auth_logs <namespace> <pod-name>"; return 1; fi
    pk -n "$1" logs -fc auth-central-grpc "$2" | "$PARSE_LOGS"
}

# ── Context Helpers ────────────────────────────────────────────
show_k8s_context() {
    echo "Current Kubernetes context:"
    kubectl config current-context
}

dev_status() {
    echo "🔍 Checking development environment status..."
    echo
    echo "📍 Current Kubernetes context:"
    kubectl config current-context
    echo
    echo "🚀 Running pods in dev-cam namespace:"
    k get pods --no-headers | head -10
}
