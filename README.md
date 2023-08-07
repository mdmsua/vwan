# Megatron PaaS vNext

## Initialize Terraform

### Prerequisites
* 1Password CARIAD-Services
* [1Password CLI](https://developer.1password.com/docs/cli/get-started)

### Initialization
From respective directory (wan / hub / spoke) run the following command:
```sh
op run --env-file ../.env -- ../init.sh
```

## Plan changes
### Wan
```sh
op run --env-file .env -- terraform plan -out main.tfplan
```
### Hub
```sh
terraform workspace select westeurope
op run --env-file .env --env-file ../.env -- terraform plan -out main.tfplan -var-file tfvars/westeurope.tfvars
```
### Spoke
```sh
terraform workspace select westeurope-berlin
op run --env-file .env --env-file ../.env -- terraform plan -out main.tfplan -var-file tfvars/westeurope/berlin.tfvars
```