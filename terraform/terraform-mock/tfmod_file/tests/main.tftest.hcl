mock_provider "google" {}

mock_resource "google_storage_bucket_object" "file" {
  id     = "mock-id"
  bucket = "mock-bucket"
  name   = "mock-name"
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
