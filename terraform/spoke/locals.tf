locals {
  resource_suffix = "${var.environment}-${var.hub}-${terraform.workspace}"
  gateway_api_crds = {
    gatewayclasses  = "standard/gateway.networking.k8s.io_gatewayclasses.yaml"
    gateways        = "standard/gateway.networking.k8s.io_gateways.yaml"
    httproutes      = "standard/gateway.networking.k8s.io_httproutes.yaml"
    referencegrants = "standard/gateway.networking.k8s.io_referencegrants.yaml"
    tlsroutes       = "experimental/gateway.networking.k8s.io_tlsroutes.yaml"
  }
}
