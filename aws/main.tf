################################################################################
# Data & Locals
################################################################################

data "aws_availability_zones" "available" {}

data "aws_caller_identity" "current" {}

locals {
  name            = "${var.demo_name}-container-escape-demo-${random_string.suffix.result}"
  cluster_version = var.kubernetes_version
  # container_name  = "${aws_ecr_repository.dvwa.repository_url}:latest"
  default_tags = {
    Name       = local.name
    GitHubRepo = "container-escape"
    GitHubOrg  = "Lunalectric"
    Terraform  = true
  }
}

resource "random_string" "suffix" {
  length  = 4
  special = false
  upper   = false
}

################################################################################
# VPC Configuration
################################################################################

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 3.14.0"

  name                 = "${local.name}-vpc"
  cidr                 = "10.0.0.0/16"
  azs                  = data.aws_availability_zones.available.names
  private_subnets      = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  public_subnets       = ["10.0.4.0/24", "10.0.5.0/24", "10.0.6.0/24"]
  enable_nat_gateway   = true
  single_nat_gateway   = true
  enable_dns_hostnames = true

  enable_flow_log                      = true
  create_flow_log_cloudwatch_iam_role  = true
  create_flow_log_cloudwatch_log_group = true

  tags = merge(
    local.default_tags, {
      "Name"                                = "${local.name}-vpc"
      "kubernetes.io/cluster/container-escape-demo" = var.demo_name
    },
  )

  public_subnet_tags = {
    "kubernetes.io/cluster/container-escape-demo" = var.demo_name
    "kubernetes.io/role/elb"              = "1"
  }

  private_subnet_tags = {
    "kubernetes.io/cluster/container-escape-demo" = var.demo_name
    "kubernetes.io/role/internal-elb"     = "1"
  }
}

################################################################################
# EKS Module
################################################################################

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 18.29.0"

  cluster_name                    = "${local.name}-cluster"
  cluster_version                 = "1.22"
  cluster_endpoint_private_access = false
  cluster_endpoint_public_access  = true

  cluster_addons = {
    coredns = {
      resolve_conflicts = "OVERWRITE"
    }
    kube-proxy = {}
    vpc-cni = {
      resolve_conflicts = "OVERWRITE"
    }
  }

  cluster_encryption_config = [{
    provider_key_arn = aws_kms_key.eks.arn
    resources        = ["secrets"]
  }]

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  manage_aws_auth_configmap = true

  # Extend cluster security group rules
  cluster_security_group_additional_rules = {
    egress_nodes_ephemeral_ports_tcp = {
      description                = "To node 1025-65535"
      protocol                   = "tcp"
      from_port                  = 1025
      to_port                    = 65535
      type                       = "egress"
      source_node_security_group = true
    }
  }

  # Extend node-to-node security group rules
  node_security_group_additional_rules = {
    ingress_self_all = {
      description = "Node to node all ports/protocols"
      protocol    = "-1"
      from_port   = 0
      to_port     = 0
      type        = "ingress"
      self        = true
    }
    egress_all = {
      description      = "Node all egress"
      protocol         = "-1"
      from_port        = 0
      to_port          = 0
      type             = "egress"
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = ["::/0"]
    }
  }

  create_iam_role          = true
  iam_role_name            = "eks-container-escape-${random_string.suffix.result}"
  iam_role_use_name_prefix = false
  iam_role_description     = "EKS role for container escape demo"
  iam_role_tags = {
    Purpose = "Protector of the kubelet"
  }
  iam_role_additional_policies = [
    "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  ]

  eks_managed_node_group_defaults = {
    ami_type       = "AL2_x86_64"
    disk_size      = 80
    instance_types = ["m5.large"]

  }
  eks_managed_node_groups = {
    complete = {
      name            = "eks-managed-nodes-${random_string.suffix.result}"
      use_name_prefix = true

      subnet_ids = module.vpc.public_subnets

      ami_type = "AL2_x86_64"

      min_size     = 1
      max_size     = 2
      desired_size = 1

      ami_id                     = data.aws_ami.eks_default.image_id
      key_name                   = var.ssh_key
      enable_bootstrap_user_data = true
      bootstrap_extra_args       = "--kubelet-extra-args '--max-pods=20'"

      pre_bootstrap_user_data = <<-EOT
      export USE_MAX_PODS=false
      EOT

      post_bootstrap_user_data = <<-EOT
      echo "you are free little kubelet!"
      EOT

      capacity_type        = "SPOT"
      disk_size            = 80
      force_update_version = true
      instance_types       = ["m5.large", "m5n.large", "m5zn.large"]
      labels = {
        GithubRepo = "terraform-aws-eks"
        GithubOrg  = "terraform-aws-modules"
      }

      update_config = {
        max_unavailable_percentage = 50 # or set `max_unavailable`
      }

      description = "${var.demo_name} EKS managed node group"

      ebs_optimized           = true
      vpc_security_group_ids  = [aws_security_group.additional.id]
      disable_api_termination = false
      enable_monitoring       = true

      block_device_mappings = {
        xvda = {
          device_name = "/dev/xvda"
          ebs = {
            volume_size           = 80
            volume_type           = "gp3"
            iops                  = 3000
            throughput            = 150
            encrypted             = true
            kms_key_id            = aws_kms_key.ebs.arn
            delete_on_termination = true
          }
        }
      }

      create_iam_role          = true
      iam_role_name            = "${var.demo_name}-iam-role"
      iam_role_use_name_prefix = false
      iam_role_description     = "${var.demo_name} EKS managed node group role"
      iam_role_tags = {
        Purpose = "Protector of the kubelet"
      }
      iam_role_additional_policies = [
        "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly",
        "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy",
        "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy",
        "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore",
        "arn:aws:iam::aws:policy/AmazonEC2FullAccess",
      ]

      create_security_group          = true
      security_group_name            = "${var.demo_name}-${random_string.suffix.result}"
      security_group_use_name_prefix = false
      security_group_description     = "${var.demo_name} EKS managed node group security group"
      security_group_rules = {
        phoneOut = {
          description = "Hello CloudFlare"
          protocol    = "udp"
          from_port   = 53
          to_port     = 53
          type        = "egress"
          cidr_blocks = ["1.1.1.1/32"]
        }
        phoneHome = {
          description                   = "Hello cluster"
          protocol                      = "udp"
          from_port                     = 53
          to_port                       = 53
          type                          = "egress"
          source_cluster_security_group = true # bit of reflection lookup
        }
      }
      security_group_tags = {
        Purpose = "Protector of the kubelet"
      }

      tags = {
        ExtraTag = "EKS managed node group complete example"
      }
    }
  }

  tags = local.default_tags
}

################################################################################
# Kali Linux Instance
################################################################################

data "aws_ami" "kali_linux" {
  most_recent = true
  owners      = ["679593333241"]

  filter {
    name   = "name"
    values = ["kali-linux-2022.*"]
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

module "ec2_instance" {
  source  = "terraform-aws-modules/ec2-instance/aws"
  version = "~> 4.1.1"

  name = "${local.name}-kali-linux"

  ami                    = data.aws_ami.kali_linux.id
  instance_type          = "t2.medium"
  key_name               = var.ssh_key
  monitoring             = true
  vpc_security_group_ids = [aws_security_group.kali_linux_access.id]
  subnet_id              = element(module.vpc.public_subnets, 0)
  user_data              = file("${path.module}/templates/setup_metapreter")

  tags = merge(
    local.default_tags, {
      "Name" = "kali-linux-hacker-instance-${random_string.suffix.result}"
    },
  )
}

resource "aws_security_group" "kali_linux_access" {
  name_prefix = "kali_linux_access_${random_string.suffix.result}"
  vpc_id      = module.vpc.vpc_id

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  ingress {
    from_port = 22
    to_port   = 22
    protocol  = "tcp"
    cidr_blocks = [
      "${var.publicIP}/32"
    ]
  }

  ingress {
    from_port = 4242
    to_port   = 4242
    protocol  = "tcp"
    cidr_blocks = [
      "0.0.0.0/0"
    ]
  }

  ingress {
    from_port = 4243
    to_port   = 4243
    protocol  = "tcp"
    cidr_blocks = [
      "0.0.0.0/0"
    ]
  }

  ingress {
    from_port = 4244
    to_port   = 4244
    protocol  = "tcp"
    cidr_blocks = [
      "0.0.0.0/0"
    ]
  }

  ingress {
    from_port = 8001
    to_port   = 8001
    protocol  = "tcp"
    cidr_blocks = [
      "0.0.0.0/0"
    ]
  }

  ingress {
    from_port = -1
    to_port   = -1
    protocol  = "icmp"
    cidr_blocks = [
      "0.0.0.0/0"
    ]
  }

  tags = local.default_tags
}

################################################################################
# Supporting Resoures
################################################################################

resource "aws_security_group" "additional" {
  name_prefix = "${var.demo_name}-eks-additional-sg-${random_string.suffix.result}"
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port = 22
    to_port   = 22
    protocol  = "tcp"
    cidr_blocks = [
      "10.0.0.0/8",
      "172.16.0.0/12",
      "192.168.0.0/16",
      "${var.publicIP}/32"
    ]
  }

  ingress {
    description       = "Cluster SG to Nodes"
    protocol          = "-1"
    from_port         = 0
    to_port           = 0
    security_groups   = [module.eks.cluster_security_group_id, module.eks.cluster_primary_security_group_id]
  }

  tags = local.default_tags
}

resource "aws_kms_key" "eks" {
  description             = "EKS Secret Encryption Key"
  deletion_window_in_days = 7
  enable_key_rotation     = true

  tags = local.default_tags
}

data "aws_ami" "eks_default" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amazon-eks-node-${local.cluster_version}-v*"]
  }
}

resource "tls_private_key" "this" {
  algorithm = "RSA"
}

resource "aws_key_pair" "this" {
  key_name   = "aws_key_${random_string.suffix.result}"
  public_key = tls_private_key.this.public_key_openssh
}

resource "aws_kms_key" "ebs" {
  description             = "Customer managed key to encrypt self managed node group volumes"
  deletion_window_in_days = 7
  policy                  = data.aws_iam_policy_document.ebs.json
}

# This policy is required for the KMS key used for EKS root volumes, so the cluster is allowed to enc/dec/attach encrypted EBS volumes
data "aws_iam_policy_document" "ebs" {
  # Copy of default KMS policy that lets you manage it
  statement {
    sid       = "Enable IAM User Permissions"
    actions   = ["kms:*"]
    resources = ["*"]

    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
    }
  }

  # Required for EKS
  statement {
    sid = "Allow service-linked role use of the CMK"
    actions = [
      "kms:Encrypt",
      "kms:Decrypt",
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*",
      "kms:DescribeKey"
    ]
    resources = ["*"]

    principals {
      type = "AWS"
      identifiers = [
        "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/aws-service-role/autoscaling.amazonaws.com/AWSServiceRoleForAutoScaling", # required for the ASG to manage encrypted volumes for nodes
        module.eks.cluster_iam_role_arn,                                                                                                            # required for the cluster / persistentvolume-controller to create encrypted PVCs
      ]
    }
  }

  statement {
    sid       = "Allow attachment of persistent resources"
    actions   = ["kms:CreateGrant"]
    resources = ["*"]

    principals {
      type = "AWS"
      identifiers = [
        "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/aws-service-role/autoscaling.amazonaws.com/AWSServiceRoleForAutoScaling", # required for the ASG to manage encrypted volumes for nodes
        module.eks.cluster_iam_role_arn,                                                                                                            # required for the cluster / persistentvolume-controller to create encrypted PVCs
      ]
    }

    condition {
      test     = "Bool"
      variable = "kms:GrantIsForAWSResource"
      values   = ["true"]
    }
  }
}

resource "aws_security_group" "remote_access" {
  name_prefix = "${local.name}-remote-access"
  description = "Allow remote SSH access"
  vpc_id      = module.vpc.vpc_id

  ingress {
    description = "SSH access"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/8", "${var.publicIP}/32"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = local.default_tags
}

resource "aws_iam_policy" "node_additional" {
  name        = "${local.name}-additional"
  description = "Example usage of node additional policy"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "ec2:Describe*",
        ]
        Effect   = "Allow"
        Resource = "*"
      },
    ]
  })

  tags = local.default_tags
}


resource "null_resource" "kubectl_config_update" {
  depends_on = [
    module.eks
  ]
  provisioner "local-exec" {
    command = "aws eks --region $(terraform output -raw region) update-kubeconfig --name $(terraform output -raw cluster_name) --kubeconfig ./eks-kubeconfig"
  }
}

################################################################################
# Install Mondoo Operator
################################################################################

#resource "null_resource" "kubectl_install_mondoo_operator" {
#  depends_on = [
#    module.eks,
#    null_resource.kubectl_config_update
#  ]
#  provisioner "local-exec" {
#    command = "kubectl --kubeconfig eks-kubeconfig apply -f https://github.com/mondoohq/mondoo-operator/releases/latest/download/mondoo-operator-manifests.yaml"
#  }
#}
#
#resource "null_resource" "kubectl_mondoo_operator_secret" {
#  depends_on = [
#    module.eks,
#    null_resource.kubectl_config_update,
#    null_resource.kubectl_install_mondoo_operator
#  ]
#  provisioner "local-exec" {
#    command = "kubectl --kubeconfig eks-kubeconfig create secret generic mondoo-client --namespace mondoo-operator --from-file=config=${var.mondoo_credentials}"
#  }
#}
#
#resource "null_resource" "kubectl_install_cert_manager" {
#  depends_on = [
#    module.eks,
#    null_resource.kubectl_config_update,
#    null_resource.kubectl_mondoo_operator_secret
#  ]
#  provisioner "local-exec" {
#    command = "kubectl --kubeconfig eks-kubeconfig apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.8.0/cert-manager.yaml"
#  }
#}
#
#resource "null_resource" "kubectl_apply_mondoo_audit_config" {
#  depends_on = [
#    module.eks,
#    null_resource.kubectl_config_update,
#    null_resource.kubectl_install_cert_manager
#  ]
#  provisioner "local-exec" {
#    command = "kubectl --kubeconfig eks-kubeconfig apply -f mondoo-config.yaml"
#  }
#}
