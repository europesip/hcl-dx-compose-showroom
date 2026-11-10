#!/usr/bin/env bash
# Collect the data HCL Support asks for when you open a case, and pack it in a .tar.gz ready to upload
# (HTTPS / SFTP). Read-only: it changes nothing in the cluster. The twin of 99-cleanup.sh.
#
# It follows the HCL technote "Collecting Data: HCL DX Containers on Kubernetes/OpenShift"
# (KB0094817), with the same file names, and adds what that note does not cover for DX Compose:
#   - wpcollector does not exist in DX Compose (Web Engine runs on Open Liberty, not WebSphere): the
#     Liberty logs of the Web Engine (messages, trace, FFDC) are copied instead, and optionally a
#     "server dump" (--liberty-dump);
#   - the third-party namespace of the labs (PostgreSQL, OpenLDAP, LiteLLM, custom MCP);
#   - the user-supplied values of every Helm release.
# Secrets are never collected (only their names), sensitive ConfigMaps are left out, and the
# values of env.sh (passwords, keys, tokens) are masked before packing.
#
# Usage:  common/collect-support-data.sh                      everything, into ./container_mustgather_<date>.tar.gz
#         common/collect-support-data.sh --case CS1234567      adds the case number to the name and the README
#         common/collect-support-data.sh --since 2h            only recent logs
#         common/collect-support-data.sh --liberty-dump        also a Liberty "server dump" of the Web Engine
#         common/collect-support-data.sh --out /some/dir       where to leave the result (default: current dir)
#
# For some problems HCL Support needs debug logging: set the "logging:" levels in your values
# (e.g. "api:server-v1:*=debug"), run the helm upgrade, reproduce the problem, then collect.
set -uo pipefail
if [ -f "$(dirname "$0")/lib.sh" ]; then
  source "$(dirname "$0")/lib.sh"
else
  # Standalone copy (e.g. inside the dx-install/ folder of the configuration wizard): the names come
  # from the environment, with the lab defaults
  info() { printf '\033[1;34m==>\033[0m %s\n' "$*"; }
  ok()   { printf '  \033[1;32mOK\033[0m    %s\n' "$*"; }
  warn() { printf '  \033[1;33mWARN\033[0m  %s\n' "$*"; }
  die()  { printf '\033[1;31m%s\033[0m\n' "$*" >&2; exit 1; }
  require_cmd() { local c; for c in "$@"; do command -v "$c" >/dev/null 2>&1 || die "Tool '$c' is not installed"; done; }
  is_openshift() { [[ "${PLATFORM:-kubernetes}" == "openshift" ]]; }
  : "${PLATFORM:=kubernetes}" "${DX_NS:=dx-demo}" "${SHARED_NS:=dx-shared}" "${DX_RELEASE:=dx-deployment}"
  : "${IQ_RELEASE:=dx-iq}" "${SEARCH_RELEASE:=dx-search}"
fi

CASE=""; SINCE=""; DUMP=0; OUTDIR="."
while [ $# -gt 0 ]; do
  case "$1" in
    --case) CASE="${2:-}"; shift ;;
    --since) SINCE="${2:-}"; shift ;;
    --liberty-dump) DUMP=1 ;;
    --out) OUTDIR="${2:-}"; shift ;;
    -h|--help) sed -n '2,24p' "$0"; exit 0 ;;
    *) die "Unknown option: $1 (see --help)" ;;
  esac
  shift
done
require_cmd kubectl helm python3 tar

K=kubectl; is_openshift && command -v oc >/dev/null 2>&1 && K=oc      # the technote: "replace kubectl by oc"
NAME="container_mustgather_${CASE:+${CASE}_}$(date +%Y%m%d-%H%M%S)"
OUT="$OUTDIR/$NAME"
mkdir -p "$OUT" || die "Cannot create $OUT"
LOGOPT=(--tail=-1); [ -n "$SINCE" ] && LOGOPT=(--since="$SINCE")
# ConfigMaps whose data is not collected: password hashes (LDIF) and the unpublished SQL script
EXCLUDE_CM="openldap-demo-ldif dx-pg-setup-sql"

info "Collecting into $OUT"

# --- Cluster level (technote: kube-version.txt, nodes.txt, CRD.txt) ---------------------------
$K version > "$OUT/kube-version.txt" 2>&1
helm version >> "$OUT/kube-version.txt" 2>&1
$K get nodes -o wide > "$OUT/nodes.txt" 2>&1
$K get crd > "$OUT/CRD-list.txt" 2>&1
# The technote asks for "describe customresourcedefinitions"; only the ones related to the labs,
# a cluster can have hundreds (Rancher, Longhorn...) and the full list is in CRD-list.txt
crds=$($K get crd -o name 2>/dev/null | grep -iE 'hcl|cnpg|postgresql' || true)
[ -n "$crds" ] && $K describe $crds > "$OUT/CRD.txt" 2>&1
$K get storageclass > "$OUT/storageclasses.txt" 2>&1

collect_ns() {   # collect_ns <namespace> <folder>
  local ns="$1" d="$2" p r
  $K get ns "$ns" >/dev/null 2>&1 || { warn "namespace $ns does not exist"; return; }
  mkdir -p "$d/logs" "$d/helm"
  info "Namespace $ns"
  # Technote: pods.txt, describePods.txt, configmap.yaml, deployment.yaml, dx-resources.txt,
  #           DX-PV.txt, DX-PVC.txt, event.txt
  $K -n "$ns" get pods -o wide > "$d/pods.txt" 2>&1
  $K -n "$ns" describe pods > "$d/describePods.txt" 2>&1
  $K -n "$ns" get configmap -o json 2>/dev/null | python3 -I -c '
import json, sys, yaml
excl = set(sys.argv[1].split()); d = json.load(sys.stdin)
for cm in d.get("items", []):
    if cm["metadata"]["name"] in excl:
        cm["data"] = {"_note": "data not collected (sensitive): excluded by collect-support-data.sh"}
    cm["metadata"].pop("managedFields", None)
    # "kubectl apply" keeps a full copy of the object (data included) in this annotation
    (cm["metadata"].get("annotations") or {}).pop("kubectl.kubernetes.io/last-applied-configuration", None)
yaml.safe_dump(d, sys.stdout, sort_keys=False, width=200)' "$EXCLUDE_CM" > "$d/configmap.yaml"
  $K -n "$ns" get deployment,statefulset -o yaml > "$d/deployment.yaml" 2>&1
  $K -n "$ns" get all -o wide > "$d/dx-resources.txt" 2>&1
  $K get pv > "$d/DX-PV.txt" 2>&1
  $K -n "$ns" get pvc -o wide > "$d/DX-PVC.txt" 2>&1
  $K -n "$ns" get event --sort-by=.lastTimestamp > "$d/event.txt" 2>&1
  $K -n "$ns" get secret -o custom-columns=NAME:.metadata.name,TYPE:.type --no-headers > "$d/secret-names.txt" 2>&1
  # Helm: releases (technote: helm ls), user-supplied values and history
  helm -n "$ns" ls > "$d/helm/helm-ls.txt" 2>&1
  for r in $(helm -n "$ns" ls -q 2>/dev/null); do
    helm -n "$ns" get values "$r" -o yaml > "$d/helm/values-$r.yaml" 2>&1
    helm -n "$ns" history "$r" > "$d/helm/history-$r.txt" 2>&1
    # Technote: currentLogs.txt (one per release: -l release=<release>)
    $K -n "$ns" logs -l "release=$r" --all-containers --prefix=true "${LOGOPT[@]}" > "$d/currentLogs-$r.txt" 2>&1 \
      || $K -n "$ns" logs -l "app.kubernetes.io/instance=$r" --all-containers --prefix=true "${LOGOPT[@]}" > "$d/currentLogs-$r.txt" 2>&1
  done
  # Every pod: current and previous logs of all its containers
  for p in $($K -n "$ns" get pods -o name 2>/dev/null); do
    p=${p#pod/}
    $K -n "$ns" logs "$p" --all-containers --prefix=true "${LOGOPT[@]}" > "$d/logs/$p.log" 2>&1
    $K -n "$ns" logs "$p" --all-containers --prefix=true --previous "${LOGOPT[@]}" > "$d/logs/$p.previous.log" 2>/dev/null \
      || rm -f "$d/logs/$p.previous.log"
  done
  # Technote: non-running pods (logs + describe)
  for p in $($K -n "$ns" get pods --no-headers 2>/dev/null | awk '{split($2,a,"/"); if ($3!="Completed" && ($3!="Running" || a[1]!=a[2])) print $1}'); do
    warn "pod not running or not ready: $p"
    $K -n "$ns" logs "$p" --all-containers --prefix=true "${LOGOPT[@]}" > "$d/non-running_pod-$p.txt" 2>&1
    $K -n "$ns" describe pod "$p" > "$d/non-running_pod_describe-$p.txt" 2>&1
  done
}

collect_ns "$DX_NS" "$OUT"
collect_ns "$SHARED_NS" "$OUT/$SHARED_NS"

# --- Technote: core-pv.yaml and dam_pv.yaml (detected, no need to pass their names) ---------
pv_of() { $K -n "$DX_NS" get pvc "$1" -o jsonpath='{.spec.volumeName}' 2>/dev/null; }
pv=$(pv_of "customization-${DX_RELEASE}-web-engine-0"); [ -n "$pv" ] && $K describe pv "$pv" > "$OUT/core-pv.yaml" 2>&1
pv=$(pv_of "${DX_RELEASE}-digital-asset-management"); [ -n "$pv" ] && $K describe pv "$pv" > "$OUT/dam_pv.yaml" 2>&1

# --- DX Compose instead of wpcollector: Liberty logs of the Web Engine -------------------------
WE="${DX_RELEASE}-web-engine-0"; LIB=/opt/openliberty/wlp/usr/servers/defaultServer
if $K -n "$DX_NS" get pod "$WE" >/dev/null 2>&1; then
  info "Web Engine Liberty logs ($WE:$LIB/logs)"
  mkdir -p "$OUT/web-engine/liberty-logs"
  $K -n "$DX_NS" exec "$WE" -c web-engine -- tar czf - -C "$LIB/logs" . 2>/dev/null | tar xzf - -C "$OUT/web-engine/liberty-logs" 2>/dev/null || true
  # tar exits 1 when a live log changes while it is read ("file changed as we read it"): check the copy instead
  [ -n "$(ls -A "$OUT/web-engine/liberty-logs" 2>/dev/null)" ] || warn "could not copy the Liberty logs"
  if ((DUMP)); then
    info "Liberty server dump (it can take a minute)"
    if $K -n "$DX_NS" exec "$WE" -c web-engine -- /opt/openliberty/wlp/bin/server dump defaultServer --archive=/tmp/support-dump.zip >/dev/null 2>&1; then
      $K -n "$DX_NS" exec "$WE" -c web-engine -- cat /tmp/support-dump.zip > "$OUT/web-engine/liberty-server-dump.zip"
      $K -n "$DX_NS" exec "$WE" -c web-engine -- rm -f /tmp/support-dump.zip
    else
      warn "server dump failed"
    fi
  fi
fi

# --- The installation and the workstation (HCL DX Compose Installer) ---------------------------
HERE="$(cd "$(dirname "$0")" && pwd)"
[ -f "$HERE/../BUILD-INFO.txt" ] && cp "$HERE/../BUILD-INFO.txt" "$OUT/BUILD-INFO.txt"
if [ -x "$HERE/environment-info.sh" ]; then
  info "Workstation, tools, Ingress and access (support/environment-info.sh)"
  "$HERE/environment-info.sh" > "$OUT/environment-info.txt" 2>&1 || warn "environment-info.sh did not finish"
fi

# --- README ---------------------------------------------------------------------------------
cat > "$OUT/README.txt" <<EOF
HCL DX Compose support data${CASE:+ · case $CASE}
Collected on $(date -u +'%Y-%m-%d %H:%M UTC') by common/collect-support-data.sh (read-only).
Platform: $PLATFORM · DX namespace: $DX_NS · third-party namespace: $SHARED_NS
Releases: DX $DX_RELEASE${IQ_RELEASE:+, IQ $IQ_RELEASE}${SEARCH_RELEASE:+, search $SEARCH_RELEASE}

Files named as in the HCL technote "Collecting Data: HCL DX Containers on Kubernetes/OpenShift"
(KB0094817): kube-version.txt, nodes.txt, CRD.txt, pods.txt, describePods.txt, configmap.yaml,
deployment.yaml, dx-resources.txt, core-pv.yaml, dam_pv.yaml, DX-PV.txt, DX-PVC.txt, event.txt,
currentLogs-<release>.txt and non-running_pod*.txt (only if some pod is not running).
Added by the installer: BUILD-INFO.txt (what the folder was generated for) and environment-info.txt
(workstation, tools, Ingress and access to DX layer by layer).

Additions:
  logs/<pod>.log, <pod>.previous.log   every container of every pod (current and previous start)
  helm/                                 helm ls, user-supplied values and history of every release
  web-engine/liberty-logs/              Open Liberty logs of the Web Engine (DX Compose has no wpcollector)
  web-engine/liberty-server-dump.zip    Liberty "server dump" (only with --liberty-dump)
  $SHARED_NS/                           the same for the third-party namespace
  CRD-list.txt, storageclasses.txt, secret-names.txt

Not collected: Secrets (only their names), the data of the ConfigMaps $EXCLUDE_CM.
Masked: passwords, keys and tokens of env.sh, LiteLLM master key, sk-... keys, LtpaToken2 and Bearer values.
EOF

# --- Mask secrets before packing -------------------------------------------------------------
info "Masking secrets"
MASK_VALUES="$(for v in HCL_HARBOR_TOKEN OPENROUTER_API_KEY LITELLM_MASTER_KEY WPSADMIN_PASSWORD LDAP_USERS_PASSWORD \
  LDAP_ADMIN_PASSWORD PG_SUPERUSER_PASSWORD DXUSER_PASSWORD IQ_DB_PASSWORD AD_BIND_PASSWORD ORACLE_DX_PASSWORD; do
  printf '%s\n' "${!v:-}"; done
  $K -n "$SHARED_NS" get secret litellm-env -o jsonpath='{.data.PROXY_MASTER_KEY}' 2>/dev/null | base64 -d 2>/dev/null; echo)" \
python3 -I - "$OUT" <<'PY'
import os, re, sys, pathlib
values = sorted({v for v in os.environ.get("MASK_VALUES", "").splitlines() if len(v) >= 4}, key=len, reverse=True)
patterns = [re.compile(p) for p in (r"sk-or-v1-[A-Za-z0-9]+", r"sk-[A-Za-z0-9]{20,}",
            r"(LtpaToken2=)[^;\s\"']+", r"(Bearer\s+)[A-Za-z0-9._~+/=-]{16,}")]
total, files = 0, 0
for f in pathlib.Path(sys.argv[1]).rglob("*"):
    if not f.is_file() or f.suffix in (".tgz", ".zip"):
        continue
    t = f.read_text(errors="replace"); n = 0
    for v in values:
        c = t.count(v)
        if c: t = t.replace(v, "***MASKED***"); n += c
    for p in patterns:
        t, c = p.subn(lambda m: (m.group(1) if m.groups() else "") + "***MASKED***", t); n += c
    if n:
        f.write_text(t); total += n; files += 1
print(f"  masked {total} value(s) in {files} file(s)")
PY

# --- Pack ------------------------------------------------------------------------------------
tar czf "$OUT.tar.gz" -C "$OUTDIR" "$NAME" || die "Could not create $OUT.tar.gz"
ok "$(du -h "$OUT.tar.gz" | cut -f1)  $OUT.tar.gz"
echo "Review it before sending (the folder $OUT is kept). Upload it to the case following the HCL"
echo "\"HTTPS and SFTP upload and download instructions\"."
exit 0
