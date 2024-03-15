import yaml
import json
import sys

def yaml_to_jsonl(yaml_file, jsonl_file):
    with open(yaml_file, 'r') as yf, open(jsonl_file, 'w') as jf:
        yaml_content = yaml.load(yf, Loader=yaml.FullLoader)
        for input_text, output_text in yaml_content.items():
            jsonl_line = json.dumps({"input_text": input_text, "output_text": output_text})
            jf.write(jsonl_line + '\n')

if __name__ == "__main__":
    if len(sys.argv) != 3:
        print("Usage: python mkjsonl.py <input_yaml_file> <output_jsonl_file>")
        sys.exit(1)
    yaml_file = sys.argv[1]
    jsonl_file = sys.argv[2]
    yaml_to_jsonl(yaml_file, jsonl_file)
