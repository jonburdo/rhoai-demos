#!/usr/bin/env bash
set -euo pipefail

command -v oc >/dev/null
oc whoami >/dev/null

NAMESPACE=${NAMESPACE:-$(oc project -q)}
if [[ -z "$NAMESPACE" ]]; then
  echo "Set NAMESPACE or select a project with 'oc project <project>'." >&2
  exit 1
fi

oc get namespace "$NAMESPACE" >/dev/null

rbac_suffix=$(printf '%s' "$NAMESPACE" | tr -cs 'a-z0-9-' '-' | sed 's/^-//; s/-$//')
CLUSTER_ROLE_NAME="rhoai-mcp-auth-${rbac_suffix}"

oc apply -f - <<EOF
apiVersion: v1
kind: ServiceAccount
metadata:
  name: rhoai-mcp
  namespace: ${NAMESPACE}
  labels:
    app.kubernetes.io/name: rhoai-mcp
    app.kubernetes.io/component: serviceaccount
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: rhoai-mcp-config
  namespace: ${NAMESPACE}
  labels:
    app.kubernetes.io/name: rhoai-mcp
    app.kubernetes.io/component: config
data:
  RHOAI_MCP_TRANSPORT: streamable-http
  RHOAI_MCP_HOST: 0.0.0.0
  RHOAI_MCP_PORT: "8000"
  RHOAI_MCP_AUTH_MODE: auto
  RHOAI_MCP_LOG_LEVEL: INFO
  RHOAI_MCP_READ_ONLY_MODE: "true"
  RHOAI_MCP_ENABLE_DANGEROUS_OPERATIONS: "false"
  RHOAI_MCP_OIDC_ENABLED: "true"
  RHOAI_MCP_OIDC_TOKEN_MODE: token-review
  RHOAI_MCP_OIDC_KUBE_AUTH_STRATEGY: user-token
  RHOAI_MCP_PLANNER_MODEL_CATALOG_URL: https://model-catalog.rhoai-model-registries.svc:8443
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: rhoai-mcp-service-ca
  namespace: ${NAMESPACE}
  labels:
    app.kubernetes.io/name: rhoai-mcp
    app.kubernetes.io/component: config
  annotations:
    service.beta.openshift.io/inject-cabundle: "true"
data: {}
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: ${CLUSTER_ROLE_NAME}
  labels:
    app.kubernetes.io/name: rhoai-mcp
    app.kubernetes.io/component: rbac
rules:
  - apiGroups:
      - authentication.k8s.io
    resources:
      - tokenreviews
    verbs:
      - create
  - apiGroups:
      - authorization.k8s.io
    resources:
      - subjectaccessreviews
    verbs:
      - create
  - apiGroups:
      - user.openshift.io
    resources:
      - users
    verbs:
      - get
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: ${CLUSTER_ROLE_NAME}
  labels:
    app.kubernetes.io/name: rhoai-mcp
    app.kubernetes.io/component: rbac
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: ${CLUSTER_ROLE_NAME}
subjects:
  - kind: ServiceAccount
    name: rhoai-mcp
    namespace: ${NAMESPACE}
EOF

echo "Created RHOAI MCP prerequisites in namespace $NAMESPACE."
echo "Use config-fragment.yaml when deploying the RHOAI MCP server from the catalog."
