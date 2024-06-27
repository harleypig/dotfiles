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
      can(regex("^filename[0-9]+\\.txt$", each.value.filename)),
      can(regex("^[r-][w-][x-]$", substr(each.value.file_permission, 0, 3))),
      can(regex("^[r-][w-][x-]$", substr(each.value.file_permission, 3, 3))),
      can(regex("^[r-][w-][x-]$", substr(each.value.file_permission, 6, 3))),
      !can(regex("x", substr(each.value.file_permission, 0, 3))),
      !can(regex("x", substr(each.value.file_permission, 3, 3))),
      !can(regex("x", substr(each.value.file_permission, 6, 3)))
    ])
    error_message = "filename must be 'filenameX.txt' where X is any valid number. file_permission must be non-executable."
  }
}
