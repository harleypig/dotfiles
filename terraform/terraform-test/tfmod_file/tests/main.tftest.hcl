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

run "bad_filename" {
  command = plan

  expect_failures = [var.files_from_yaml]

  variables {
    test_filenames = {
      "badfile.txt" = {
        filename = "badfile.txt"
        content  = "This should fail"
      }
    }
  }
}
