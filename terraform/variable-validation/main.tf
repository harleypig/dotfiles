locals {
  files_from_yaml = {
    for f in try(fileset(var.data_folder, "**/*.yaml"), []) : f => yamldecode(file("${var.data_folder}/${f}"))
  }
}

module "yaml_file" {
  source          = "./tfmod_file"
  files_from_yaml = local.files_from_yaml
}
