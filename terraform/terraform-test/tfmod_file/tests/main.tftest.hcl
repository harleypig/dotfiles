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

  expect_failures = ["All filenames must match the pattern 'filenameXXX.txt' where XXX is any number."]

  variables {
    test_filenames = {
      "badfile.txt" = {
        filename = "badfile.txt"
        content  = "This should fail"
      }
    }
  }
}
