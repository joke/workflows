variable "name" {
  type        = string
  description = "Repository name, without the owner."
}

variable "description" {
  type        = string
  description = "Repository description."
}

variable "topics" {
  type        = list(string)
  description = "Repository topics."
  default     = []
}

variable "required_checks" {
  type = list(object({
    context        = string
    integration_id = optional(number)
  }))
  description = "Status checks required before merging to main. integration_id ties a check to the app that reports it; it is omitted where the ruleset API rejects it."
}
