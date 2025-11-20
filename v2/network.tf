resource "oci_core_virtual_network" "vcn" {
  compartment_id = var.compartment_ocid
  cidr_block     = var.vcn_cidr
  dns_label      = var.vcn_dns_label
  display_name   = var.vcn_dns_label
}

# Internet Gateway
resource "oci_core_internet_gateway" "igw" {
  compartment_id = var.compartment_ocid
  display_name   = "${var.vcn_dns_label}igw"
  vcn_id         = oci_core_virtual_network.vcn.id
}

# Public Route Table
resource "oci_core_route_table" "PublicRT" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_virtual_network.vcn.id
  display_name   = "${var.vcn_dns_label}pubrt"

  route_rules {
    destination       = "0.0.0.0/0"
    network_entity_id = oci_core_internet_gateway.igw.id
  }
}

resource "oci_core_subnet" "subnet" {
  availability_domain = ""
  compartment_id      = var.compartment_ocid
  vcn_id              = oci_core_virtual_network.vcn.id
  cidr_block          = cidrsubnet(var.vcn_cidr, 8, 1)
  display_name        = var.dns_label
  dns_label           = var.dns_label
  route_table_id      = oci_core_route_table.PublicRT.id
  security_list_ids   = [oci_core_security_list.securitylist.id]
}

resource "oci_core_security_list" "securitylist" {
  display_name   = "SL_public"
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_virtual_network.vcn.id

  egress_security_rules {
    protocol    = "all"
    destination = "0.0.0.0/0"
  }

  ingress_security_rules {
    # 1. Tráfico desde el exterior (Internet - 0.0.0.0/0) al puerto 80
    protocol = "6"
    source   = "0.0.0.0/0"
    source_type = "CIDR_BLOCK" # Asegúrate de que esto está en tu archivo
    tcp_options {
      min = 80
      max = 80
    }
  }

  # 2. Tráfico desde el exterior (Internet - 0.0.0.0/0) al puerto 22 (SSH)
  ingress_security_rules {
    protocol = "6"
    source   = "0.0.0.0/0"
    source_type = "CIDR_BLOCK" # Asegúrate de que esto está en tu archivo
    tcp_options {
      min = 22
      max = 22
    }
  }

  # 3. Tráfico INTERNO de la VCN al puerto 80 (Para el Health Checker del Load Balancer)
  ingress_security_rules {
    protocol = "6"
    source   = var.vcn_cidr # Permite a cualquier IP de la VCN (incluido el LB) acceder al 80
    source_type = "CIDR_BLOCK" 
    tcp_options {
      min = 3000 # Cambio de puerto (anteriormente 80)
      max = 3000
    }
  }
}

