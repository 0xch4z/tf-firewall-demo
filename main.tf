provider "linode" {
  api_version = "v4beta"
}

locals {
  common_tags = ["app=firewall-demo"]

  users = ["0xcharles"]
}

data "linode_instance_type" "standard_1" {
  id = "g6-standard-1"
}

resource "linode_instance" "api_instance" {
  label  = "api"
  group  = "firewall-demo"
  type   = data.linode_instance_type.standard_1.id
  region = "us-east"

  disk {
    label      = "boot"
    filesystem = "ext4"
    image      = "linode/ubuntu19.04"
    root_pass  = "bogus-password$"
    size       = data.linode_instance_type.standard_1.disk - 256

    authorized_users = local.users
  }

  disk {
    label      = "swap"
    filesystem = "swap"
    size       = 256
  }

  config {
    label  = "boot_config"
    kernel = "linode/latest-64bit"

    devices {
      sda {
        disk_label = "boot"
      }
      sdb {
        disk_label = "swap"
      }
    }
  }

  boot_config_label = "boot_config"

  tags = local.common_tags

  provisioner "file" {
    source      = "src/hello_server.py"
    destination = "/usr/local/bin/hello_server"

    connection {
      type     = "ssh"
      user     = "root"
      password = self.disk[0].root_pass
      host     = self.ip_address
    }
  }

  provisioner "file" {
    source      = "src/hello_server.service"
    destination = "/etc/systemd/system/hello_server.service"

    connection {
      type     = "ssh"
      user     = "root"
      password = self.disk[0].root_pass
      host     = self.ip_address
    }
  }

  provisioner "remote-exec" {
    inline = [
      "chmod 744 /usr/local/bin/hello_server",
      "chmod 644 /etc/systemd/system/hello_server.service",
      "systemctl daemon-reload",
      "systemctl enable hello_server.service",
      "systemctl start hello_server.service"
    ]

    connection {
      type     = "ssh"
      user     = "root"
      password = self.disk[0].root_pass
      host     = self.ip_address
    }
  }
}

resource "linode_firewall" "api_firewall" {
  label = "api-firewall"
  tags  = local.common_tags

  # allow SSH-ing from company VPN
  inbound {
    protocol  = "TCP"
    ports     = ["22"]
    addresses = ["0.0.0.0/0"]
  }

  # allow HTTP/S broadcast 
  # inbound {
  #   protocol  = "TCP"
  #   ports     = ["80", "443"]
  #   addresses = ["0.0.0.0/0"]
  # }

  linodes = [
    linode_instance.api_instance.id
  ]
}

output "linode_ip" {
  value = linode_instance.api_instance.ip_address
}
