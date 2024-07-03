variable "files_from_yaml" {
  description = "files in the module"
  type = map(object({
    filename             = string
    content              = string
    file_permission      = string
    directory_permission = string
  }))

  validation {
    condition = alltrue([
      for filename, file in var.files_from_yaml :
      can(regex("^filename\\d+\\.txt$", filename))
    ])
    error_message = "All filenames must match the pattern 'filenameXXX.txt' where XXX is any number."
  }
}
