locals {
  hub      = split("-", terraform.workspace)[0]
  spoke    = split("-", terraform.workspace)[1]
  location = data.terraform_remote_state.hub.outputs.location
}
