import json
import os

# Define color codes
COLORS = {
    'directory': '\033[01;34m',  # Blue
    'executable': '\033[01;32m',  # Green
    'file': '\033[00m',  # Default
    'reset': '\033[0m'  # Reset
}

# Define symbols
SYMBOLS = {
    'directory': '/',
    'executable': '*',
    'file': ''
}

def colorize(name, file_type):
    return f"{COLORS[file_type]}{name}{SYMBOLS[file_type]}{COLORS['reset']}"

def parse_json(json_data, indent=0):
    output = []
    for item in json_data:
        if item['type'] == 'directory':
            output.append(f"{' ' * indent}└─[{item['mode']}] {colorize(item['name'], 'directory')}")
            output.extend(parse_json(item['contents'], indent + 3))
        else:
            file_type = 'executable' if item['mode'] == '0755' else 'file'
            output.append(f"{' ' * indent}├─[{item['mode']}] {colorize(item['name'], file_type)}")
    return output

def main():
    import sys
    json_input = sys.stdin.read()
    json_data = json.loads(json_input)
    tree_output = parse_json(json_data)
    print("\n".join(tree_output))

if __name__ == "__main__":
    main()
