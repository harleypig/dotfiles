mock_provider "google" {}

mock_resource "google_storage_bucket_object" "file" {
  id     = "mock-id"
  bucket = "mock-bucket"
  name   = "mock-name"
}

mock_resource "local_file" "yaml_files" {
  id     = "mock-id"
  filename = "mock-filename"
  content  = "mock-content"
  file_permission = "mock-permission"
  directory_permission = "mock-directory-permission"
}

run "good_filename" {
  command = plan

  variables {
    test_filenames = {
      "filename42.txt" = {
        filename = "filename42.txt"
        content  = "This should succeed"
      }
    }
  }
}
