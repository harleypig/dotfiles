variable "yaml_localfile" {
  type    = string
  default = "yaml/localfile.yml"
}

locals {
  file_yaml_data = yamldecode(file(var.yaml_localfile))
}

#resource "local_file" "example-local-file" {
#  filename        = local.file_yaml_data.filename
#  content         = local.file_yaml_data.content
#  file_permission = local.file_yaml_data.file_permission
#}
