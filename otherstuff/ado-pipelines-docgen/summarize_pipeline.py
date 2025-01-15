#!/usr/bin/env python3

import argparse
import sys
import yaml
import os

#-----------------------------------------------------------------------------
def warn(message):
    """Print a message to stderr."""
    print(message, file=sys.stderr)

#-----------------------------------------------------------------------------
def load_file(pipeline_file):
    """Load and parse the YAML pipeline file."""
    try:
        with open(pipeline_file, 'r') as file:
            pipeline = yaml.safe_load(file)

            if pipeline is None:
                raise ValueError("YAML file is empty or contains no valid data")

            return pipeline

    except PermissionError:
        warn(f"Error: Permission denied when trying to read {pipeline_file}")
        exit(1)

    except FileNotFoundError:
        warn(f"Error: File not found: {pipeline_file}")
        exit(1)

    except yaml.YAMLError as exc:
        warn(f"Error: Could not parse YAML file: {exc}")
        exit(1)

    except ValueError as ve:
        warn(f"Error: {ve}")
        exit(1)

#-----------------------------------------------------------------------------
def summarize_pipeline(pipeline_file):
    pipeline = load_file(pipeline_file)

    summary = {
        "name": pipeline.get('name', 'Unnamed Pipeline'),
        "trigger": pipeline.get('trigger', {}),
        "variables": pipeline.get('variables', {})
    }

    return summary

def generate_markdown(summary):
    markdown = f"# Pipeline Summary: {summary['name']}\n\n"
    markdown += "## Triggers\n"
    if summary['trigger']:
        markdown += f"- **Branches**: {', '.join(summary['trigger'].get('branches', ['None']))}\n"
        markdown += f"- **Tags**: {', '.join(summary['trigger'].get('tags', ['None']))}\n"
    else:
        markdown += "- No triggers defined\n"

    markdown += "\n## Variables\n"
    if summary['variables']:
        for var, value in summary['variables'].items():
            markdown += f"- **{var}**: {value}\n"
    else:
        markdown += "- No variables defined\n"

    markdown += "\n## Jobs\n"
    for job in summary['jobs']:
        markdown += f"- **{job['name']}**\n"
        markdown += f"  - Steps: {job['steps']}\n"
        markdown += f"  - Pool: {job['pool']}\n"

    return markdown

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Summarize Azure DevOps Pipeline YAML")
    parser.add_argument("pipeline_file", help="Path to the Azure DevOps pipeline YAML file")
    args = parser.parse_args()

    if not os.path.exists(args.pipeline_file):
        print(f"File {args.pipeline_file} does not exist.")
        exit(1)

    summary = summarize_pipeline(args.pipeline_file)
    if summary:
        markdown = generate_markdown(summary)
        with open('otherstuff/ado-pipelines-docgen/pipeline_summary.md', 'w') as md_file:
            md_file.write(markdown)
        print(f"Markdown summary has been written to otherstuff/ado-pipelines-docgen/pipeline_summary.md")
