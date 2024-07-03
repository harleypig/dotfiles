module "test_files" {
  source          = "../"
  files_from_yaml = var.test_filenames
}
