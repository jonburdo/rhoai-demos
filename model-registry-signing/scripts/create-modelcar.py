#!/usr/bin/env python
# coding: utf-8

get_ipython().system("uv pip install -q 'model-registry[olot]'")


import os
from pathlib import Path

from model_registry.utils import save_to_oci_registry


# registry auth (i.e. instead of ~/.docker/config.json)
os.environ["REGISTRY_AUTH_FILE"] = "/tmp/auth.json"


model_path = Path.home() / "my-model"


save_to_oci_registry(
    base_image="quay.io/jburdo/busybox:latest",
    oci_ref="quay.io/jburdo/my-model:v1",
    model_files_path=model_path,
)
