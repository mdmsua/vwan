locals {
  hub      = split("-", terraform.workspace)[0]
  spoke    = split("-", terraform.workspace)[1]
  location = data.terraform_remote_state.hub.outputs.location
  gateway_api_crds = {
    gatewayclasses  = "standard/gateway.networking.k8s.io_gatewayclasses.yaml"
    gateways        = "standard/gateway.networking.k8s.io_gateways.yaml"
    httproutes      = "standard/gateway.networking.k8s.io_httproutes.yaml"
    referencegrants = "standard/gateway.networking.k8s.io_referencegrants.yaml"
    tlsroutes       = "experimental/gateway.networking.k8s.io_tlsroutes.yaml"
  }
}
