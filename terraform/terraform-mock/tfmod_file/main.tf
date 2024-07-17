locals {
  files_from_yaml = {
    for f in var.files_from_yaml : f["filename"] => f
  }
}

resource "local_file" "yaml_files" {
  for_each = local.files_from_yaml

  filename             = each.key
  content              = each.value["content"]
  file_permission      = each.value["file_permission"]
  directory_permission = each.value["directory_permission"]
}

resource "google_storage_bucket_object" "file" {
  for_each   = local.files_from_yaml
  depends_on = [local_file.yaml_files]

  bucket = var.bucket_name
  name   = basename(each.key)
  source = each.key
}
