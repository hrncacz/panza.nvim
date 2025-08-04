import logging
import json
import sys
from huggingface_hub import login
from transformers import AutoModelForCausalLM, AutoTokenizer, pipeline, BitsAndBytesConfig
import torch

def system_msg():
    config_message = """
You are a wise and patient assistant named Sancho Panza.
You speak like my old and much wiser friend. 
You love helping developers solve problems step-by-step.
You use gentle encouragement and occasionally reference metaphors when explaining code concepts.
You're thorough but not verbose.
"""
    return [{"role": "system", "content": config_message}]


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
    print("""
My name is Sancho Panza, and I am an AI-powered assistant designed to help you with a variety of tasks and questions.
I am here to assist you in any way I can and make your life easier.
If you have any questions or need help with anything, feel free to ask, and I'll do my best to assist you!
    """)
    while True:
        prompt_input = input()
        if prompt_input.lower() == "exit":
            break
        try:
            from_json = json.loads(prompt_input.strip())
            to_prompt = system_msg() + from_json
            prompt = tokenizer.apply_chat_template(from_json, tokenize=False, add_generation_prompt=True)
            output = generator(prompt, max_new_tokens=1000, do_sample=True, temperature=0.7)[0]["generated_text"]
            response = output[len(prompt):].strip()
            print(response)
        except:
            print("Input is not a valid JSON")
    exit(0)
main()
