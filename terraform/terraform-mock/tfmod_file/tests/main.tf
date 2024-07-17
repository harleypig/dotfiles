module "test_files" {
  source          = "../"
  files_from_yaml = var.test_filenames
  project_id      = var.project_id
  region          = var.region
  bucket_name     = var.bucket_name
}
