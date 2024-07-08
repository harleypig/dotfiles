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

#run "bad_filename" {
#  command = plan
#
#  variables {
#    test_filenames = {
#      "badfile.txt" = {
#        filename = "badfile.txt"
#        content  = "This should fail"
#      }
#    }
#  }
#
#  #expect_failures = [bad_filename.files_from_yaml]
#  #expect_failures = [bad_filename.files_from_yaml.filename]
#  #expect_failures = [bad_filename.files_from_yaml.filename["badfile.txt"]]
#  #expect_failures = [bad_filename.test_filenames]
#  #expect_failures = [bad_filename.test_filenames.filename]
#  #expect_failures = [bad_filename.test_filenames.filename["badfile.txt"]]
#
#  #expect_failures = [module.bad_filename.files_from_yaml]
#  #expect_failures = [module.bad_filename.files_from_yaml.filename]
#  #expect_failures = [module.bad_filename.files_from_yaml.filename["badfile.txt"]]
#  #expect_failures = [module.bad_filename.test_filenames]
#  #expect_failures = [module.bad_filename.test_filenames.filename]
#  #expect_failures = [module.bad_filename.test_filenames.filename["badfile.txt"]]
#
#  #expect_failures = [test_files.files_from_yaml]
#  #expect_failures = [test_files.files_from_yaml.filename]
#  #expect_failures = [test_files.files_from_yaml.filename["badfile.txt"]]
#  #expect_failures = [test_files.test_filenames]
#  #expect_failures = [test_files.test_filenames.filename]
#  #expect_failures = [test_files.test_filenames.filename["badfile.txt"]]
#
#  #expect_failures = [test_filenames]
#  #expect_failures = [test_filenames.filename]
#  #expect_failures = [test_filenames.filename["badfile.txt"]]
#
#  #expect_failures = [test_files]
#  #expect_failures = [test_files.test_filenames]
#  #expect_failures = [test_files.test_filenames.filename]
#
#  #expect_failures = [var.files_from_yaml]
#  #expect_failures = [var.files_from_yaml.filename]
#
#  #expect_failures = [var.test_filenames]
#  #expect_failures = [var.test_filenames.filename]
#
#  #expect_failures = [module.test_files.validation_check]
#}
