locals {
  _files_from_yaml_raw = flatten([
    for file in try(fileset(var.data_folder, "**/*.yaml"), []) : [
      for key, newfile in yamldecode(file("${var.data_folder}/${file}")) :
      merge(newfile, {
        filename             = "${var.filename_pattern}"
        content              = newfile.content
        file_permission      = newfile.permissions
        directory_permission = try(newfile.directory_permission, null)
      })
    ]
  ])

  files_from_yamlb = {
    for f in local._files_from_yaml_raw : f["filename"] => f
  }
}

module "yaml_file" {
  source          = "./tfmod_file"
  files_from_yaml = local.files_from_yamlb
}
