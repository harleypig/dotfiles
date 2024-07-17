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

  variables {
    project_id  = "mock-project-id"
    region      = "mock-region"
    bucket_name = "mock-bucket-name"
  }

  mock {
    path     = "google_storage_bucket_object.file"
    response = {
      id     = "mock-id"
      bucket = "mock-bucket"
      name   = "mock-name"
    }
  }
}
