# Notes

## Allow for specific version?

See
[this](https://github.com/coreyramirezgomez/ansible-role-github-release-retriever/blob/main/tasks/main.yml)
for ideas to steal.

## add 'Authorization' header if token defined

```
- name: set github http headers
  set_fact:
    github_get_files_http_headers: "{{ github_get_files_http_headers | combine({'Authorization': 'token ' + github_get_files_token} if github_get_files_token else {}) }}"
```
