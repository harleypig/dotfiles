terraform {
  required_version = ">=1.3.2"
  required_providers {
    local = {
      source  = "hashicorp/local"
      version = "2.2.3"
    }
  }
}

variable "data_folder" {
  description = "Path for folders defined as YAML objects"
  type        = string
  default     = "myfolder"
}

module "yaml_file" {
  source          = "../.."
  files_from_yaml = local.files_from_yamlb
}

locals {
  _files_from_yaml_raw = flatten([
    for file in try(fileset(var.data_folder, "**/*.yaml"), []) : [
      for key, newfile in yamldecode(file("${var.data_folder}/${file}")) :
      merge(newfile, {
        filename             = "${key}"
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

terraform {
  required_version = ">=1.3.2"
  required_providers {
    local = {
      source  = "hashicorp/local"
      version = "2.2.3"
    }
  }
}

run "bad_filename" {
  expect_fail = true

  config = {
    module "yaml_file" {
      source          = "../.."
      files_from_yaml = {
        "badfile.txt" = {
          filename             = "badfile.txt"
          content              = "This should fail"
          file_permission      = "0644"
          directory_permission = "0755"
        }
      }
    }
  }
}

run "good_filename" {
  expect_fail = false

  config = {
    module "yaml_file" {
      source          = "../.."
      files_from_yaml = {
        "filename123.txt" = {
          filename             = "filename123.txt"
          content              = "This should succeed"
          file_permission      = "0644"
          directory_permission = "0755"
        }
      }
    }
  }
}
