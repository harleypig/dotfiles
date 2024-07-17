mock_provider "google" {
  mock_resource "google_storage_bucket_object" {}
}

run "good_filename" {
  command = plan

  variables {
    project_id  = "mock-id"
    region      = "mock-region"
    bucket_name = "mock-bucket"

    test_filenames = {
      "filename42.txt" = {
        filename = "filename42.txt"
        content  = "This should succeed"
      }
    }
  }
}
