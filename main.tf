provider "aws" {
    region = var.region
    access_key = var.aws_access_key
    secret_key = var.aws_secret_key
}

# EKS IAM Roles and policies

resource "aws_iam_role_policy_attachment" "eks_cluster_policy" {
    role       = aws_iam_role.eks_cluster_role.name
    policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

resource "aws_iam_role_policy_attachment" "eks_service_policy" {
    role       = aws_iam_role.eks_cluster_role.name
    policy_arn = "arn:aws:iam::aws:policy/AmazonEKSServicePolicy"
}

resource "aws_iam_role" "eks_cluster_role" {
    name = "${var.name}-cluster-role"

    assume_role_policy = jsonencode({
        Version = "2012-10-17"
        Statement = [
            {
                Action = "sts:AssumeRole"
                Effect = "Allow"
                Principal = {
                    Service = "eks.amazonaws.com"
                }
            },
        ]
    })
}

# VPC and subnet for EKS cluster

resource "aws_subnet" "eks_subnet" {
    vpc_id            = aws_vpc.eks_vpc.id
    cidr_block        = "10.0.1.0/24"
    availability_zone = var.availability_zone
}

resource "aws_vpc" "eks_vpc" {
    cidr_block = "10.0.0.0/16"
}

# EKS cluster
resource "aws_eks_cluster" "new_cluster" {
    name     = "${var.name}-cluster"
    role_arn = aws_iam_role.eks_cluster_role.arn

    vpc_config {
        subnet_ids = [aws_subnet.eks_subnet.id] 
    }
}

### Worker nodes ###

# Nodes IAM Roles and policies

resource "aws_iam_role_policy_attachment" "eks_worker_node_policy" {
  role       = aws_iam_role.eks_node_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}

resource "aws_iam_role_policy_attachment" "eks_cni_policy" {
  role       = aws_iam_role.eks_node_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}

resource "aws_iam_role_policy_attachment" "ec2_container_registry_read_only" {
  role       = aws_iam_role.eks_node_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

resource "aws_iam_role" "eks_node_role" {
  name = "${var.name}-node-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      },
    ]
  })
}

# Node group for EKS cluster
resource "aws_eks_node_group" "eks_nodes" {
  cluster_name    = aws_eks_cluster.new_cluster.name
  node_group_name = "eks-dev-node-group"
  node_role_arn   = aws_iam_role.eks_node_role.arn
  subnet_ids      = [aws_subnet.eks_subnet.id]

  scaling_config { 
    desired_size = 1
    max_size     = 3
    min_size     = 1
  }

  instance_types = ["t2.micro"] 
  disk_size      = 10           # Size in GB

  ami_type = "AL2_x86_64" # Amazon Linux 2 AMI
}