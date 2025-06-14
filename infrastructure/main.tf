resource "aws_vpc" "cicd" {
    cidr_block = "10.0.0.0/16"
    enable_dns_hostnames = true  
}

resource "aws_subnet" "subnet_1" {
    vpc_id = aws_vpc.cicd.id
    cidr_block = "10.0.0.0/20"
    availability_zone = "ap-south-1a"
    map_public_ip_on_launch = true  
}

#resource "aws_subnet" "subnet_2" {
#    vpc_id = aws_vpc.cicd.id
#    cidr_block = "10.0.16.0/20"
#    availability_zone = "ap-south-1b"
#    map_public_ip_on_launch = true  
#}
#
#resource "aws_subnet" "subnet_3" {
#    vpc_id = aws_vpc.cicd.id
#    cidr_block = "10.0.32.0/20"
#    availability_zone = "ap-south-1c"
#    map_public_ip_on_launch = true  
#}

resource "aws_internet_gateway" "internet_gw" {
    vpc_id = aws_vpc.cicd.id
}

resource "aws_route_table" "route_table" {
    vpc_id = aws_vpc.cicd.id

    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.internet_gw.id
    }

    route {
        cidr_block = "10.0.0.0/16"
        gateway_id = "local"
    } 
}

resource "aws_route_table_association" "sub_1_association" {
    subnet_id = aws_subnet.subnet_1.id
    route_table_id = aws_route_table.route_table.id
}

#resource "aws_route_table_association" "sub_2_association" {
#    subnet_id = aws_subnet.subnet_2.id
#    route_table_id = aws_route_table.route_table.id
#}
#
#resource "aws_route_table_association" "sub_3_association" {
#    subnet_id = aws_subnet.subnet_3.id
#    route_table_id = aws_route_table.route_table.id
#}

#variable "aws_instance" {
#    default = {
#        "KubeMaster" = "t2.medium",
#        "KubeWorker" = "t2.small"
#    }
#}

resource "aws_instance" "KubeMaster" {
    ami = "ami-0b09627181c8d5778" # Example AMI, replace with a valid one for your region
    instance_type = "t2.medium"
    key_name = "test_server" # Replace with your actual key pair name
    subnet_id = aws_subnet.subnet_1.id
    associate_public_ip_address = true

    tags = {
        Name = "KubeMaster"
        Role = "Master"
    }

    # Only run provisioner on KubeMaster
    provisioner "remote-exec" {
        inline = [
            "sudo yum update -y",
            "sudo yum install docker -y",
            "sudo systemctl enable docker",
            "sudo systemctl start docker",
            "sudo usermod -aG docker ec2-user",
            "sudo wget https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64",
            "sudo chmod +x minikube-linux-amd64",
            "sudo mv minikube-linux-amd64 /usr/local/bin/minikube",
            "sudo curl -LO https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/linux/amd64/kubectl",
            "sudo chmod +x kubectl",
            "sudo mv kubectl /usr/local/bin/kubectl",
            # if needed to Start Minikube (Docker driver) as a part of inline script
            # "sudo minikube start --driver=docker"
            "sudo usermod -aG docker ec2-user"
        ]
        connection {
            type = "ssh"
            host = self.public_ip
            user = "ec2-user"
            private_key = file("${pathexpand("C:/Users/100173/Downloads/test_server.pem")}")

            # Increase the timeout to allow Minikube to start if line 94 is enabled to start the minikube as part of the inline script
            # timeout = "10m"
        }
    }
}

resource "aws_instance" "KubeWorker" {
    ami = "ami-0b09627181c8d5778" # Example AMI, replace with a valid one for your region
    instance_type = "t2.small"
    key_name = "test_server" # Replace with your actual key pair name
    subnet_id = aws_subnet.subnet_1.id
    associate_public_ip_address = true

    tags = {
        Name = "KubeWorker"
        Role = "Worker"
    }
}    


#module "eks" {
#  source  = "terraform-aws-modules/eks/aws"
#  version = "20.36.0"
#
#  cluster_name    = "my-cluster-eks"
#  cluster_version = "1.27"
#
#  cluster_endpoint_public_access = true
#  enable_cluster_creator_admin_permissions = true
#  #cluster_endpoint_public_access = true
#  #cluster_endpoint_public_access_cidrs = ["0.0.0.0/0"]
#
#  vpc_id                   = aws_vpc.cicd.id
#  subnet_ids               = [aws_subnet.subnet_1.id, aws_subnet.subnet_2.id, aws_subnet.subnet_3.id]
#  control_plane_subnet_ids = [aws_subnet.subnet_1.id, aws_subnet.subnet_2.id, aws_subnet.subnet_3.id]
#
#  eks_managed_node_groups = {
#    green = {
#      min_size       = 1
#      max_size       = 1
#      desired_size   = 1
#      instance_types = ["t3.medium"]
#    }
#  }
#}
#test
