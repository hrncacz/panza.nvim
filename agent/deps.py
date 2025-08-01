import logging
import json
import sys
from huggingface_hub import login
from transformers import AutoModelForCausalLM, AutoTokenizer, pipeline, BitsAndBytesConfig
import torch

def deps():
    exit(0)

deps()
