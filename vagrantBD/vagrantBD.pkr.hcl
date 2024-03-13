packer {
  required_plugins {
    virtualbox = {
      version = ">= 0.0.1"
      source  = "github.com/hashicorp/virtualbox"
    }
    vagrant = {
      version = ">= 0.0.1"
      source  = "github.com/hashicorp/vagrant"
    }
  }
}

source "virtualbox-vm" "alpineNormal" {
    guest_additions_mode = "disable"
    output_directory = "output-virtualbox-vm"
    communicator = "ssh"
    ssh_username = "vagrant"
    ssh_password = "vagrant"
    ssh_timeout = "2h"
    headless = "false"
    shutdown_command = "sudo -S shutdown -P now"
    vm_name = "alpineNormal"
    attach_snapshot = "alpine"
    target_snapshot = "2024-03-12"
    force_delete_snapshot = true
    keep_registered = false
    skip_export = false

    vboxmanage = [
        ["modifyvm", "{{ .Name }}", "--natpf1", "CASSANDRA,tcp,,9042,,9042"],
        ["modifyvm", "{{ .Name }}", "--natpf1", "MONGODB,tcp,,27017,,27017"],
        ["modifyvm", "{{ .Name }}", "--natpf1", "MYSQL,tcp,,3306,,3306"],
        ["modifyvm", "{{ .Name }}", "--natpf1", "REDIS,tcp,,6379,,6379"]
        
    ]
}

build {
    sources = ["source.virtualbox-vm.alpineNormal"]

    
    provisioner "shell" {
        inline = [
            # Añadimos los repositorios para instalar docker y edge 
            "echo 'http://dl-cdn.alpinelinux.org/alpine/v3.19/community' | sudo tee -a /etc/apk/repositories",
            "sudo apk update",
        ]
    }


    #Instalamos docker según viene en la documentación
    provisioner "shell" {
        inline = [
            "sudo apk update", 
            "sudo apk add docker docker-compose",
            "sudo rc-update add docker boot",
            "sudo service docker start",
            "sudo addgroup vagrant docker", 
            "sudo docker info", 
            "sudo service docker restart", 
            "sleep 20", 
        ]
    }

    #Creamos los volumenes para las bd
    provisioner "shell" {
        inline = [
            "sudo mkdir -p /home/vagrant/cassandra-data",
            "sudo mkdir -p /home/vagrant/mongodb-data",
            "sudo mkdir -p /home/vagrant/mysql-data",
            "sudo mkdir -p /home/vagrant/redis-data"
            
        ]
    }


    # Copiamos docker-compose.yml 
    provisioner "file" {
        source      = "docker-compose.yml"
        destination = "/home/vagrant/docker-compose.yml"
    }

    # Copiamos init.sql a la mv cortesia de jose
    provisioner "file" {
        source      = "init.sql"
        destination = "/home/vagrant/init.sql"
    }

    post-processors {
        post-processor "vagrant" {
            output = "output-virtualbox-vm/vm-docker.box"
            compression_level = "9"
            keep_input_artifact = true
        }
        post-processor "vagrant-cloud" {
            box_tag     = ""
            access_token = ""
            version     = "1"
            
        }
    } 
}