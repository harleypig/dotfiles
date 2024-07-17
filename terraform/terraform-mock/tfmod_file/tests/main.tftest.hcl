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
