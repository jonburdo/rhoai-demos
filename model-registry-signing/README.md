# model-registry-signing-dev

Development notebooks and scripts for model signing using [model-registry](https://github.com/kubeflow/model-registry).

## Workflow

1. **Download a model** from Hugging Face (`download-model`)
2. **Create a ModelCar** OCI image from the model files (`create-modelcar`)
3. **Sign and verify** model files and OCI images (`signing`)

## Usage

### Notebooks

Interactive versions are in [`notebooks/`](notebooks/).

### Scripts

Python scripts are in [`scripts/`](scripts/). They were generated from the notebooks with:

```sh
jupyter nbconvert --to script --no-prompt \
  --TemplateExporter.exclude_markdown=True \
  --TemplateExporter.exclude_raw=True \
  notebooks/*.ipynb
mv notebooks/*.py scripts/
ruff format scripts/
```

## Configuration

The signer requires four Sigstore environment variables which can be provided be an instance of a custom connection type:

| Variable | Description |
|----------|-------------|
| `SIGSTORE_TUF_URL` | TUF server URL for certificate/key management |
| `SIGSTORE_FULCIO_URL` | Fulcio server URL for issuing signing certificates |
| `SIGSTORE_REKOR_URL` | Rekor server URL for transparency log entries |
| `SIGSTORE_TSA_URL` | Timestamp Authority server URL |

For authentication, the signer uses an OIDC identity token. By default it reads the Kubernetes service account token at `/var/run/secrets/kubernetes.io/serviceaccount/token`. To use a different token, pass `identity_token_path`:

```python
signer = Signer(identity_token_path="/path/to/token")
```

## Signing example

```python
from model_registry.signing import Signer

signer = Signer()

model_path = Path.home() / "my-model"

signer.sign_model(model_path)
signer.verify_model(model_path)

image_digest_ref = "quay.io/org/model@sha256:c8d35b84f8b56e17224e1a234f23138754e5dba35da367036aaac58ebdf2e9c6"

signer.sign_image(image_digest_ref)
signer.verify_image(image_digest_ref)
```

For more verbose output, set the log level when creating the signer:

```python
import logging

signer = Signer(log_level=logging.INFO)   # or logging.DEBUG for maximum detail
```
