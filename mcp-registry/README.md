# mcp-registry

Files for deploying rhoai-mcp-server from the RHOAI MCP Registry.

`server-json/` contains server definitions for `com.redhat/rhoai-mcp-server`.
`scripts/rhoai-mcp-server-setup.sh` creates the namespace-local prerequisites required by the server.

## Setup

Log in with `oc`, then run:

```sh
NAMESPACE=<project> ./scripts/rhoai-mcp-server-setup.sh
```

Without `NAMESPACE`, the script uses the current OpenShift project. It creates
the `rhoai-mcp` ServiceAccount, the required ConfigMaps, and a narrowly scoped
ClusterRole and ClusterRoleBinding for token review and authorization checks.
