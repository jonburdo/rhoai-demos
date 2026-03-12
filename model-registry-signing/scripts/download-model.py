#!/usr/bin/env python
# coding: utf-8

get_ipython().system("uv pip install -q huggingface-hub")


import os
from pathlib import Path

from huggingface_hub import snapshot_download


model_path = Path.home() / "my-model"
snapshot_download(repo_id="bert-base-uncased", local_dir=model_path)


get_ipython().system("du -sh $model_path")


get_ipython().system("find $model_path")
