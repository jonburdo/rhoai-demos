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

## Use the registry from Python

The MLflow MCP registry is available through the tracking client configured by
`MLFLOW_TRACKING_URI`. The examples below require `mlflow>=3.15.0` and a tracking
server with MCP registry support.

```python
import os

import mlflow

# MLFLOW_TRACKING_URI must point to the MLflow tracking server that hosts
# the MCP registry.
mlflow.set_tracking_uri(os.environ["MLFLOW_TRACKING_URI"])

servers = mlflow.genai.search_mcp_servers(
    filter_string="status = 'active'",
    max_results=100,
)

for server in servers:
    print(server.name, server.description)
```

Search filters can use server tags. Tags are useful for discovery and
classification, such as team or environment. They are mutable metadata, so do
not use a tag as the only guarantee that a particular server release will be
used.

```python
servers = mlflow.genai.search_mcp_servers(
    filter_string="status = 'active' AND tags.team = 'platform'",
    max_results=100,
)

for server in servers:
    print(server.name, server.tags)
```

To inspect versions for this server and then resolve a specific version, use
the server name and the exact version string. The registry version identifies
the registered `server.json` definition and tool snapshot; it is separate from
the container image tag in `packages[].identifier`.

```python
server_name = "com.redhat/rhoai-mcp-server"

versions = mlflow.genai.search_mcp_server_versions(
    name=server_name,
    filter_string="status = 'active'",
    max_results=100,
)
for item in versions:
    print(item.version, item.status, item.tags)

# Pin to an exact registry version for reproducible automation.
pinned_version = mlflow.genai.get_mcp_server_version(
    name=server_name,
    version="0.1.1",
)
print(pinned_version.server_json)
```

For a deployment channel such as `production` or `staging`, use a registry
alias. An alias points to one version and can be moved deliberately during a
rollout. Resolve it at runtime when you want controlled updates; use an exact
version when you need an immutable selection for a job or release.

```python
# A registry administrator or release process manages this mapping.
mlflow.genai.set_mcp_server_alias(
    name="com.redhat/rhoai-mcp-server",
    alias="production",
    version="0.1.1",
)

production_version = mlflow.genai.get_mcp_server_version_by_alias(
    name="com.redhat/rhoai-mcp-server",
    alias="production",
)
print(production_version.version)
```

The registry's access endpoint is the URL clients connect to. It is stored
separately from `server.json` remotes, which describe the server's published
remote locations. Look up an access endpoint for a specific pinned version
like this:

```python
endpoints = mlflow.genai.search_mcp_access_endpoints(
    server_name="com.redhat/rhoai-mcp-server",
    server_version="0.1.1",
)

for endpoint in endpoints:
    print(endpoint.url, endpoint.transport_type)
```

A good release practice is to promote reviewed versions through aliases, while
recording the resolved exact version in deployment configuration or logs. Use
exact version pins for reproducible workflows, and avoid relying on `latest`
for production automation because its resolution can change as versions are
published or activated. Keep server tags descriptive and stable enough for
search, and use aliases to represent channels that intentionally move.
