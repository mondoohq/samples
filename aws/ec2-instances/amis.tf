////////////////////////////////
// AMIs

data "aws_ami" "amazon2023" {
  most_recent = true

  filter {
    name   = "name"
    values = ["al2023-ami-2023*"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["137112412989"]
}

data "aws_ami" "amazon2" {
  most_recent = true

  filter {
    name   = "name"
    values = ["amzn2-ami-kernel-5.10-hvm-2.0.2023*"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["137112412989"]
}

data "aws_ami" "amazon2_cis" {
  most_recent = true

  filter {
    name   = "name"
    values = ["CIS Amazon Linux 2 *Level 2*"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["679593333241"]
}

data "aws_ami" "rhel8" {
  most_recent = true

  filter {
    name   = "name"
    values = ["RHEL_HA-8.6.0_HVM-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["309956199498"]
}

data "aws_ami" "rhel8_cis" {
  most_recent = true

  filter {
    name   = "name"
    values = ["CIS Red Hat Enterprise Linux 8*Level 2*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["679593333241"]
}

data "aws_ami" "rhel9_cis" {
  most_recent = true

  filter {
    name   = "name"
    values = ["CIS Red Hat Enterprise Linux 9*Level 2*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["679593333241"]
}

data "aws_ami" "nginx_rhel9_cis" {
  most_recent = true

  filter {
    name   = "name"
    values = ["CIS NGINX on Red Hat Enterprise Linux 9 Benchmark*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["679593333241"]
}

data "aws_ami" "nginx_win2019" {
  most_recent = true

  filter {
    name   = "name"
    values = ["NGINX2019-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["679593333241"]
}



data "aws_ami" "rhel9" {
  most_recent = true

  filter {
    name   = "name"
    values = ["RHEL-9.5*x86_64*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["309956199498"]
}

data "aws_ami" "ubuntu1804" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-bionic-18.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] // Canonical
}

data "aws_ami" "ubuntu2004" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] // Canonical
}

data "aws_ami" "ubuntu2004_cis" {
  most_recent = true

  filter {
    name   = "name"
    values = ["CIS Ubuntu Linux 20.04 LTS Benchmark*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["679593333241"]
}

data "aws_ami" "ubuntu2204" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] // Canonical
}

data "aws_ami" "ubuntu2204_cis" {
  most_recent = true

  filter {
    name   = "name"
    values = ["CIS Ubuntu Linux 22.04*"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["679593333241"]
}

data "aws_ami" "ubuntu2204_cis_arm64" {
  most_recent = true

  filter {
    name   = "name"
    values = ["CIS Ubuntu Linux 22.04*ARM*"]
  }

  filter {
    name   = "architecture"
    values = ["arm64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["679593333241"]
}

# Ubuntu 24.04
data "aws_ami" "ubuntu2404" {
  most_recent = true

  filter {
    name   = "name"
    values = ["*ubuntu-noble-24.04-amd64-server*"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] // Canonical
}

data "aws_ami" "ubuntu2404_arm64" {
  most_recent = true

  filter {
    name   = "name"
    values = ["*ubuntu-noble-24.04-arm64-server*"]
  }

  filter {
    name   = "architecture"
    values = ["arm64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["679593333241"]
}

data "aws_ami" "debian10" {
  most_recent = true

  filter {
    name   = "name"
    values = ["debian-10-amd64-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["136693071363"]
}

data "aws_ami" "debian11" {
  most_recent = true

  filter {
    name   = "name"
    values = ["debian-11-amd64-2023*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["136693071363"]
}

data "aws_ami" "debian11_cis" {
  most_recent = true

  filter {
    name   = "name"
    values = ["CIS Debian Linux 11*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["679593333241"]
}

data "aws_ami" "debian12" {
  most_recent = true

  filter {
    name   = "name"
    values = ["debian-12-amd64-2023*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["136693071363"]
}

data "aws_ami" "debian12_cis" {
  most_recent = true

  filter {
    name   = "name"
    values = ["CIS Debian Linux 12*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["679593333241"]
}

data "aws_ami" "suse15" {
  most_recent = true

  filter {
    name   = "name"
    values = ["suse-sles-15-sp5*"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["013907871322"]
}

data "aws_ami" "suse15_cis" {
  most_recent = true

  filter {
    name   = "name"
    values = ["CIS SUSE Linux Enterprise 15 Benchmark*Level*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["679593333241"]
}

data "aws_ami" "oracle8_cis" {
  most_recent = true

  filter {
    name   = "name"
    values = ["CIS Oracle Linux 8 Benchmark*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["679593333241"]
}

data "aws_ami" "oracle9" {
  most_recent = true

  filter {
    name   = "name"
    values = ["*(SupportedImages) - Oracle Linux 9 LATEST x86_64*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["679593333241"]
}


data "aws_ami" "oracle9_cis" {
  most_recent = true

  filter {
    name   = "name"
    values = ["CIS Oracle Linux 9 Benchmark*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["679593333241"]
}

data "aws_ami" "rocky9" {
  most_recent = true

  filter {
    name   = "name"
    values = ["Rocky-9-EC2-Base*x86_64*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["792107900819"]
}

data "aws_ami" "rocky9_cis" {
  most_recent = true

  filter {
    name   = "name"
    values = ["CIS Rocky Linux 9 Benchmark*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["679593333241"]
}

data "aws_ami" "winserver2016" {
  most_recent = true

  filter {
    name   = "name"
    values = ["Windows_Server-2016-English-Full-Base-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["801119661308"]
}

data "aws_ami" "winserver2016_cis" {
  most_recent = true

  filter {
    name   = "name"
    values = ["CIS Microsoft Windows Server 2016 Benchmark*Level 2*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["679593333241"]
}

data "aws_ami" "winserver2019" {
  most_recent = true

  filter {
    name   = "name"
    values = ["Windows_Server-2019-English-Full-Base-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["801119661308"]
}

data "aws_ami" "winserver2019_cis" {
  most_recent = true

  filter {
    name   = "name"
    values = ["CIS Microsoft Windows Server 2019 Benchmark *Level 2*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["679593333241"]
}

data "aws_ami" "winserver2022" {
  most_recent = true

  filter {
    name   = "name"
    values = ["Windows_Server-2022-English-Full-Base-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["801119661308"]
}

data "aws_ami" "winserver2022_cis" {
  most_recent = true

  filter {
    name   = "name"
    values = ["CIS Microsoft Windows Server 2022 Benchmark *Level 2*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["679593333241"]
}

data "aws_ami" "winserver2022_german" {
  most_recent = true

  filter {
    name   = "name"
    values = ["Windows_Server-2022-German-Full-Base-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["801119661308"]
}

data "aws_ami" "winserver2022_italian" {
  most_recent = true

  filter {
    name   = "name"
    values = ["Windows_Server-2022-Italian-Full-Base-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["801119661308"]
}
