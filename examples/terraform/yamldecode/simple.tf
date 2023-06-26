variable "yaml_simplefile" {
  type    = string
  default = "yaml/simple.yml"
}

locals {
  simple_yaml_data = yamldecode(file(var.yaml_simplefile))
}

#output "simple_yaml_data" {
#  value = local.simple_yaml_data
#}

#output "simple_yaml_hi" {
#  value = local.simple_yaml_data.hithere
#}
