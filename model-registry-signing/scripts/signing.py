#!/usr/bin/env python
# coding: utf-8

get_ipython().system("uv pip install -q 'model-registry[signing]'")


get_ipython().system("uv pip show model-registry")


import logging
import os
from pathlib import Path

from model_registry.signing import Signer


# registry auth (i.e. instead of ~/.docker/config.json)
os.environ["REGISTRY_AUTH_FILE"] = "/tmp/auth.json"


signer = Signer()


model_path = Path.home() / "my-model"


signer.sign_model(model_path)


signer.verify_model(model_path)


image_digest_ref = "quay.io/jburdo/my-model@sha256:c8d35b84f8b56e17224e1a234f23138754e5dba35da367036aaac58ebdf2e9c6"


signer.sign_image(image_digest_ref)


signer.verify_image(image_digest_ref)
