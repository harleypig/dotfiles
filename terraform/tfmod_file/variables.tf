variable "files_from_yaml" {
  description = "files in the module"
  type = map(object({
    filename             = string
    content              = string
    file_permission      = string
    directory_permission = string
  }))
  
  validation {
    condition = can(regex("^filename[0-9]+\\.txt$", each.value.filename))
    error_message = "filename must be 'filenameX.txt' where X is any valid number."
  }

  validation {
    condition = alltrue([
      can(regex("^filename[0-9]+\\.txt$", each.value.filename)),
      can(regex("^0[0-7]{3}$", each.value.file_permission)),
      !contains(tolist([1, 3, 5, 7]), tonumber(substr(each.value.file_permission, 1, 1))),
      !contains(tolist([1, 3, 5, 7]), tonumber(substr(each.value.file_permission, 2, 1))),
      !contains(tolist([1, 3, 5, 7]), tonumber(substr(each.value.file_permission, 3, 1)))
    ])
    error_message = "file_permission must be a valid 4-digit number and non-executable."
  }
}