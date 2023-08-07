#!/usr/bin/env bash

terraform init -upgrade \
    -backend-config="tenant_id=$TF_VAR_state_tenant_id" \
    -backend-config="subscription_id=$TF_VAR_state_subscription_id" \
    -backend-config="resource_group_name=$TF_VAR_state_resource_group_name" \
    -backend-config="storage_account_name=$TF_VAR_state_storage_account_name" \
    -backend-config="container_name=$TF_VAR_state_container_name"