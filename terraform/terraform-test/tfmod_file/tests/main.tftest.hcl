run "bad_filename" {
  command = plan
  variables {
    test_filenames = {
      badfile = {
        filename = "badfile.txt"
        content  = "This should fail"
      }
    }
  }
}

run "good_filename" {
  command = plan
  variables {
    test_filenames = {
      goodfile = {
        filename = "filename42.txt"
        content  = "This should succeed"
      }
    }
  }
}
