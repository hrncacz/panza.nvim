import logging
import json
import sys
from huggingface_hub import login
from transformers import AutoModelForCausalLM, AutoTokenizer, pipeline, BitsAndBytesConfig
import torch
def main():
    hf_api_key = None
    for i in sys.argv:
        if "hf_api_key" in i:
            hf_api_key = i.split("=")[-1]
    if hf_api_key is None:
        print("Missing hf_api_key argument")
        exit(1)

    logging.getLogger("transformers").setLevel(logging.ERROR)
    login(hf_api_key)
    bnb_config = BitsAndBytesConfig(
        load_in_4bit=True,
        bnb_4bit_compute_dtype=torch.float16,
        bnb_4bit_use_double_quant=True,
        bnb_4bit_quant_type="nf4",
    )
    device = 0 if torch.cuda.is_available() else -1
    model_name = "teknium/OpenHermes-2.5-Mistral-7B"
    tokenizer = AutoTokenizer.from_pretrained(model_name, use_fast=False)
    model = AutoModelForCausalLM.from_pretrained(model_name, device_map="auto", use_safetensors=True, quantization_config=bnb_config)
    generator = pipeline("text-generation", model=model, tokenizer=tokenizer)
    print("Sancho Panza is ready to help you!")
    while True:
        prompt_input = input()
        if prompt_input.lower() == "exit":
            break
        try:
            from_json = json.loads(prompt_input.strip())
            prompt = tokenizer.apply_chat_template(from_json, tokenize=False, add_generation_prompt=True)
            output = generator(prompt, max_new_tokens=1000, do_sample=True, temperature=0.7)[0]["generated_text"]
            response = output[len(prompt):].strip()
            print(response)
        except:
            print("Input is not a valid JSON")
    exit(0)
main()
