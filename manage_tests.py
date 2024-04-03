import os
import subprocess
from jinja2 import Environment, FileSystemLoader

# Configuration
REPO_HOME = os.getenv('DOTFILES', os.path.expanduser('~/dotfiles'))
TESTS_DIR = os.path.join(REPO_HOME, 'tests')
BIN_DIR = os.path.join(REPO_HOME, 'bin')
LIB_DIR = os.path.join(REPO_HOME, 'lib')
TEMPLATE_DIR = os.path.join(TESTS_DIR, 'templates')
TEMPLATE_FILE = 'file.meta.bats.j2'

# Initialize Jinja2 environment
env = Environment(loader=FileSystemLoader(TEMPLATE_DIR))
template = env.get_template(TEMPLATE_FILE)

def find_files(directory, pattern):
    """Find files by pattern."""
    cmd = ['find', directory, '-type', 'f', '-name', pattern]
    result = subprocess.run(cmd, capture_output=True, text=True)
    return result.stdout.strip().split('\n')

def generate_meta_tests(files):
    """Generate meta tests for files."""
    for file_path in files:
        file_name = os.path.basename(file_path)
        test_path = os.path.join(TESTS_DIR, 'checks', file_name + '.t', file_name + '.meta.bats')
        os.makedirs(os.path.dirname(test_path), exist_ok=True)
        with open(test_path, 'w') as f:
            f.write(template.render(filename=file_name, filepath=file_path))

def main():
    # Find all script files in bin and lib directories
    bin_files = find_files(BIN_DIR, '*.sh')
    lib_files = find_files(LIB_DIR, '*.sh')
    
    # Generate meta tests
    generate_meta_tests(bin_files + lib_files)
    print(f"Generated meta tests for {len(bin_files) + len(lib_files)} files.")

if __name__ == '__main__':
    main()
