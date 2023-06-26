variable "yaml_filefor" {
  type    = string
  default = "yaml/file1.yml"
}

locals {
  _factory = [for k, v in yamldecode(file(var.yaml_filefor)) :
    merge(v, {
      description     = "${k}"
      filename        = v.filename
      content         = v.content
      file_permission = v.file_permission
  })]
}

#resource "local_file" "example-file1" {
#  filename        = local.file1_yaml_data.file1.filename
#  content         = local.file1_yaml_data.file1.content
#  file_permission = local.file1_yaml_data.file1.file_permission
#}

#output "show_filefor" {
#  value = local._factory
#}
