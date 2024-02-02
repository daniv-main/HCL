

packer {
  required_plugins {
    virtualbox = {
      version = "~> 1"
      source  = "github.com/hashicorp/virtualbox"
    }
    vagrant = {
      version = "~> 1"
      source = "github.com/hashicorp/vagrant"
    }
  }
}

variable "iso_url" {
  type    = string
  #default = "https://dl-cdn.alpinelinux.org/alpine/v3.18/releases/x86/alpine-standard-3.18.2-x86.iso"
  default = "https://dl-cdn.alpinelinux.org/alpine/v3.19/releases/x86_64/alpine-standard-3.19.0-x86_64.iso"
}

variable "iso_checksum" {
  type    = string
  default = "sha256:4cf7cd3bad64122a8a2423e78369a486a02334d4d88645aab9d08120bb76b0f9"
}

variable "vm_name" {
  type    = string
  default = "alpine-3.19.0-x86_64"
}

variable "guest_os_type_virtualbox" {
  type    = string
  default = "alpine_64"
}

variable "guest_os_type_vmware" {
  type    = string
  default = "other5xlinux"
}

variable "install_dev" {
  type    = string
  default = "/dev/sda"
}

variable "msys_dev" {
  type    = string
  default = "/dev/sda3"
}

variable "root_password" {
  type    = string
  default = "vagrant"
}

variable "vagrant_password" {
  type    = string
  default = "vagrant"
}

# https://developer.hashicorp.com/packer/plugins/builders/virtualbox/iso
source "virtualbox-iso" "alpine" {
  vm_name              = "${var.vm_name}"
  communicator         = "ssh"
# cdrom_adapter_type   = "sata"
  disk_size            = "8192"
# disk_adapter_type    = "nvme"
  format               = "ova"
  guest_additions_mode = "disable"
  guest_os_type        = "${var.guest_os_type_virtualbox}"
  headless             = false
  iso_checksum         = "${var.iso_checksum}"
  iso_url              = "${var.iso_url}"
  #Para depurar descomentar########################
  keep_registered      = true  #mantiene la máquina virtualbox una vez realizado todo (util para depurar, comentar si no)
  #################################################
  output_directory     = "output-${var.vm_name}"
  shutdown_command     = "/sbin/poweroff"

  ssh_password         = "${var.root_password}"
  ssh_timeout          = "3m"
  ssh_username         = "root"
  usb                  = true
  vboxmanage           = [
	["modifyvm", "{{ .Name }}", "--memory", "256"],
	["modifyvm", "{{ .Name }}", "--vram", "33"],
	["modifyvm", "{{ .Name }}", "--ioapic", "on"],
	["modifyvm", "{{ .Name }}", "--cpus", "2"],
	["modifyvm", "{{ .Name }}", "--rtcuseutc", "on"],
	["modifyvm", "{{ .Name }}", "--graphicscontroller", "vmsvga"],
	["modifyvm", "{{ .Name }}", "--chipset", "ich9"],
	["modifyvm", "{{ .Name }}", "--nic1", "nat"],
	["modifyvm", "{{ .Name }}", "--nictype1", "virtio"],
	["modifyvm", "{{ .Name }}", "--cableconnected1", "on"],
	["modifyvm", "{{ .Name }}", "--nat-localhostreachable1", "on"],
	["modifyvm", "{{ .Name }}", "--audio-enabled", "off"],
	["modifyvm", "{{ .Name }}", "--audio-in", "off"],
	["modifyvm", "{{ .Name }}", "--audio-out", "off"],
	["modifyvm", "{{ .Name }}", "--audio-controller", "ac97"],
	["modifyvm", "{{ .Name }}", "--vrde", "off"],
	["modifyvm", "{{ .Name }}", "--usbohci", "off"],
	["modifyvm", "{{ .Name }}", "--usbehci", "off"],
	["modifyvm", "{{ .Name }}", "--usbxhci", "off"]
  ]
// # boot_key_interval    = "15ms"
//   boot_wait            = "20s"
//    boot_command         = [<<EOF
//    root<enter><wait1s>
//    <enter><wait1s>
// 	 date -u -s ${formatdate("YYYYMMDDhhmm.ss", timestamp())}<enter><wait>
// 	 hwclock -u -w<enter><wait>
//    setup-alpine <enter><wait1s>
//    es<enter><wait>
//    es<enter><wait>
//    <enter><wait>
//    <enter><wait>
//    <enter><wait>
//    <enter><wait3>
// 	 ${var.root_password}<enter><wait1s>
// 	 ${var.root_password}<enter><wait20s>
//    <enter><wait>
//    <enter><wait>
//    <enter><wait>
//    <enter><wait>
//    <enter><wait>
//    <enter><wait>
//    <enter><wait>
//    sda<enter><wait>
//    sys<enter><wait2s>
//    y<enter><wait3s>
//    reboot<enter><wait1s>
// 	 EOF
// 	 ]

  boot_command         = [<<EOF
	root<enter><wait1>
	date -u -s ${formatdate("YYYYMMDDhhmm.ss", timestamp())}<enter><wait>
	hwclock -u -w<enter><wait>
	cat<<EOA>answers<enter>
	KEYMAPOPTS="es es"<enter>
	HOSTNAMEOPTS=alpine<enter>
	DEVDOPTS=mdev<enter>
	INTERFACESOPTS="auto lo<enter>
	iface lo inet loopback<enter>
	<enter>
	auto eth0<enter>
	iface eth0 inet dhcp<enter>
	    hostname alpine<enter>
	"<enter>
	DNSOPTS="-d example.com 8.8.8.8"<enter>
	TIMEZONEOPTS=UTC<enter>
	PROXYOPTS=none<enter>
	APKREPOSOPTS=-1<enter>
	USEROPTS="-a -u -g audio,video,netdev,dialout vagrant"<enter>
	SSHDOPTS=openssh<enter>
	NTPOPTS=busybox<enter>
	DISKOPTS="-m sys ${var.install_dev}"<enter>
	EOA<enter><wait>
	setup-alpine -f answers<enter><wait10>
	${var.root_password}<enter><wait1>
	${var.root_password}<enter><wait20s>
	y<enter><wait20s>
	mount ${var.msys_dev} /mnt<enter><wait>
	echo 'PermitRootLogin yes' >> /mnt/etc/ssh/sshd_config<enter><wait>
	cat /mnt/etc/apk/repositories<enter><wait>
	umount /mnt<enter><wait1>
	reboot<enter><wait40s>
	EOF
	]
}

build {
  sources = [
    "source.virtualbox-iso.alpine"
  ]
  provisioner "shell" {
    inline = [
      "echo 'vagrant:${var.vagrant_password}' | chpasswd",
      "sed '/PermitRootLogin yes/d' -i /etc/ssh/sshd_config"
    ]
  }

  provisioner "shell" {
    scripts = [
      "./scripts/x-apk-update.sh"
    ]
  }
  
  provisioner "shell" {
    inline = [
      "setup-keymap es es"
    ]
  }

  #SSH
  provisioner "shell" {
    inline = [
      "cd /home/vagrant",
      "chmod 2755 .",
      "mkdir -m 700 .ssh",
      "wget https://raw.githubusercontent.com/hashicorp/vagrant/main/keys/vagrant.pub",
      "mv vagrant.pub .ssh/authorized_keys",
      "chmod 600 .ssh/authorized_keys",
      "chown vagrant:vagrant .ssh .ssh/*"
    ]

  } 

  // provisioner "shell" {
  //   scripts = [
  //     "./scripts/x-apk-update.sh",
  //     #"x-only-virtualbox.sh",
  //     #"x-provision.sh",
  //     #"x-vmdiskclean.sh"
  //   ]
  // }



  #GuestAdditions
  provisioner "shell" {
    inline = [
      "apk add virtualbox-guest-additions",
      "rc-update add virtualbox-guest-additions",
      "rc-update add local",
      "addgroup vagrant vboxsf"
    ]

  }  
  
   
  
  #Docker
  provisioner "shell" {
    inline = [
      "apk add docker",
      "addgroup root docker",
      "rc-update add docker default",
      "service docker start"
    ]

  }  
  
  #post-processor "shell-local" {
  #  inline = [
  #    "echo convert ${var.vm_name}.ova to ${var.vm_name}.box...",
  #    "perl perl-ova2box.pl output-${var.vm_name}/${var.vm_name}.ova output-${var.vm_name}/${var.vm_name}.box"
  #  ]
  #}
  
  post-processors {
    
    post-processor "vagrant" {
      output = "output-${var.vm_name}/${var.vm_name}.box" #output-${var.vm_name}/
      compression_level = 9
      keep_input_artifact = true # eso mantiene el OVF+VMDK intermedio. 
    } 
    /**/ 
    #vagrant-cloud : comentado. si el token no es válido no hará nada (chequea conexion antes de empezar)
    // post-processor "vagrant-cloud" {
    // #https://developer.hashicorp.com/packer/integrations/hashicorp/vagrant/latest/components/post-processor/vagrant-cloud 
    //   box_tag     = "danielvillegasce/alpinePruebas"
    //   access_token = ""
    //   version     = "1.1"
    //   #architecture= "unknown"
    // } 
    /**/
  }

}