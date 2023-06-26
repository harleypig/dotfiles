variable "yaml_file1" {
  type    = string
  default = "yaml/file1.yml"
}

locals {
  file1_yaml_data = yamldecode(file(var.yaml_file1))
}

#resource "local_file" "example-file1" {
#  filename        = local.file1_yaml_data.file1.filename
#  content         = local.file1_yaml_data.file1.content
#  file_permission = local.file1_yaml_data.file1.file_permission
#}
