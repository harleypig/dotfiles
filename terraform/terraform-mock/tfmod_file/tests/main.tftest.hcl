mock_provider "google" {}

run "good_filename" {
  command = plan

  variables {
    project_id  = "mock-project-id"
    region      = "mock-region"
    bucket_name = "mock-bucket-name"

    test_filenames = {
      "filename42.txt" = {
        filename = "filename42.txt"
        content  = "This should succeed"
      }
    }
  }
}
