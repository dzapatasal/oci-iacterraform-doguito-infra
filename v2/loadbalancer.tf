resource "oci_load_balancer" Load_Balancer {
  compartment_id = var.compartment_ocid
  display_name = "DPS-LB" # fN : "Demo-Web-LB"
  shape          = "flexible"
  subnet_ids = [
    oci_core_subnet.subnet.id,
  ]
  shape_details {
      #Required
      maximum_bandwidth_in_mbps = var.load_balancer_max_band
      minimum_bandwidth_in_mbps = var.load_balancer_min_band
    }
}
resource "oci_load_balancer_backend_set" web-servers-backend {
  health_checker {
    interval_ms         = "15000" # aumentamos el intervalo (10000 anteriormente)
    port                = "3000" # cambio de puerto (80 anteriormente)
    protocol            = "HTTP"
    response_body_regex = ""
    retries             = "5" # aumentamos el numero de intentos (de 3 a 5)
    return_code         = "200"
    timeout_in_millis   = "5000" # aumentamos intervalo (de 3000 a 5000)
    url_path            = "/"
  }
  load_balancer_id = oci_load_balancer.Load_Balancer.id
  name             = "web-servers-backend"
  policy           = "ROUND_ROBIN"
}
resource "oci_load_balancer_backend" dps-vm1 {
  backendset_name  = oci_load_balancer_backend_set.web-servers-backend.name
  backup           = "false"
  drain            = "false"
  load_balancer_id = oci_load_balancer.Load_Balancer.id
  ip_address       = oci_core_instance.dps-server-01.private_ip # cambio del nombre del backend 01
  offline          = "false"
  port             = "3000" # cambio de puerto (del 80 a 3000)
  weight           = "1"
}
resource "oci_load_balancer_backend" dps-vm2 {
  backendset_name  = oci_load_balancer_backend_set.web-servers-backend.name
  backup           = "false"
  drain            = "false"
  load_balancer_id = oci_load_balancer.Load_Balancer.id
  ip_address       = oci_core_instance.dps-server-02.private_ip # cambio del nombre del backend 02
  offline          = "false"
  port             = "3000" # cambio de puerto (del 80 a 3000)
  weight           = "1"
}
resource "oci_load_balancer_listener" lb-listeners {
  connection_configuration {
    backend_tcp_proxy_protocol_version = "0"
    idle_timeout_in_seconds            = "60"
  }
  default_backend_set_name = oci_load_balancer_backend_set.web-servers-backend.name
  hostname_names = [
  ]
  load_balancer_id = oci_load_balancer.Load_Balancer.id
  name             = "lb-listeners"
  port     = "80"
  protocol = "HTTP"
  rule_set_names = [
  ]
}

# fN: formerName