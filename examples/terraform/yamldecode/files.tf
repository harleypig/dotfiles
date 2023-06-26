variable "yaml_files" {
  type    = string
  default = "yaml/files.yml"
}

locals {
  _files_factory = flatten([
    for k, v in yamldecode(file(var.yaml_files)) :
    merge(v, {
      description     = "${k}"
      filename        = v.filename
      content         = v.content
      file_permission = v.file_permission
  })])
}

resource "local_file" "example-files" {
  for_each = local._files_factory

  filename        = each.value["filename"]
  content         = each.value["content"]
  file_permission = each.value["file_permission"]
}

#output "show_files" {
#  value = local._files_factory
#}
