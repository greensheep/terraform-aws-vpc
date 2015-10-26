
########################
## Required variables ##
########################

variable "vpc_name" {
    description = "The name of the VPC. Best not to include non-alphanumeric characters."
}

variable "vpc_region" {
    description = "Target region for the VPC"
}

variable "vpc_nat_ami" {
    description = "NAT instamce AMI id"
    default = {
        eu-west-1      = "ami-6975eb1e"
        eu-central-1   = "ami-46073a5b"
        us-west-1      = "ami-7da94839"
        us-west-2      = "ami-69ae8259"
        us-east-1      = "ami-303b1458"
        ap-northeast-1 = "ami-03cf3903"
        ap-southeast-1 = "ami-b49dace6"
        ap-southeast-2 = "ami-e7ee9edd"
        sa-east-1      = "ami-fbfa41e6"
    }
}

variable "vpc_nat_instance_type" {
    description = "Instance type to use for the NAT instance"
    default = "t2.micro"
}

variable "vpc_nat_detailed_monitoring" {
    description = "Enable detailed monitoring for the NAT instance"
    default = "false"
}

variable "vpc_nat_key_file" {
    description = "Path to a key file for the VPC NAT instance"
}

#########
## VPC ##
#########

# The VPC contains six subnets, three public and three private, one
# for each availability zone. Instances in the private subnets can
# communicate with the outside via a NAT instance.

resource "aws_vpc" "main" {
    
    cidr_block = "10.0.0.0/16"
    enable_dns_support = true
    enable_dns_hostnames = true
    
    tags {
        Name = "${var.vpc_name}"
    }

    lifecycle {
        create_before_destroy = true
    }

}

#####################
## Private Subnets ##
#####################

resource "aws_subnet" "private_1" {

    vpc_id = "${aws_vpc.main.id}"
    availability_zone = "${var.vpc_region}a"
    cidr_block = "10.0.1.0/24"
    map_public_ip_on_launch = false

    tags {
        Name = "${var.vpc_name}-Private Subnet 1"
        VPC = "${var.vpc_name}"
    }

    lifecycle {
        create_before_destroy = true
    }

}

resource "aws_subnet" "private_2" {

    vpc_id = "${aws_vpc.main.id}"
    availability_zone = "${var.vpc_region}b"
    cidr_block = "10.0.2.0/24"
    map_public_ip_on_launch = false

    tags {
        Name = "${var.vpc_name}-Private Subnet 2"
        VPC = "${var.vpc_name}"
    }

    lifecycle {
        create_before_destroy = true
    }

}

resource "aws_subnet" "private_3" {

    vpc_id = "${aws_vpc.main.id}"
    availability_zone = "${var.vpc_region}c"
    cidr_block = "10.0.3.0/24"
    map_public_ip_on_launch = false
    
    tags {
        Name = "${var.vpc_name}-Private Subnet 3"
        VPC = "${var.vpc_name}"
    }

    lifecycle {
        create_before_destroy = true
    }
    
}

####################
## Public Subnets ##
####################

resource "aws_subnet" "public_1" {
    
    vpc_id = "${aws_vpc.main.id}"
    availability_zone = "${var.vpc_region}a"
    cidr_block = "10.0.11.0/24"
    map_public_ip_on_launch = true

    tags {
        Name = "${var.vpc_name}-Public Subnet 1"
        VPC = "${var.vpc_name}"
    }

    lifecycle {
        create_before_destroy = true
    }

}

resource "aws_subnet" "public_2" {
    
    vpc_id = "${aws_vpc.main.id}"
    availability_zone = "${var.vpc_region}b"
    cidr_block = "10.0.22.0/24"
    map_public_ip_on_launch = true
    
    tags {
        Name = "${var.vpc_name}-Public Subnet 2"
        VPC = "${var.vpc_name}"
    }

    lifecycle {
        create_before_destroy = true
    }

}

resource "aws_subnet" "public_3" {
    
    vpc_id = "${aws_vpc.main.id}"
    availability_zone = "${var.vpc_region}c"
    cidr_block = "10.0.33.0/24"
    map_public_ip_on_launch = true

    tags {
        Name = "${var.vpc_name}-Public Subnet 3"
        VPC = "${var.vpc_name}"
    }

    lifecycle {
        create_before_destroy = true
    }

}

######################
## Internet gateway ##
######################

resource "aws_internet_gateway" "gateway" {

    vpc_id = "${aws_vpc.main.id}"

    tags {
        Name = "${var.vpc_name}-Internet-Gateway"
        VPC = "${var.vpc_name}"
    }

    lifecycle {
        create_before_destroy = true
    }

}

##################
## Route tables ##
##################

# Re-maps the "main" route table to our custom one
resource "aws_main_route_table_association" "main_routes" {

    vpc_id = "${aws_vpc.main.id}"
    route_table_id = "${aws_route_table.private_routes.id}"

}

#####################################
## Route tables: private instances ##
#####################################

# Routes traffic through the NAT instance
resource "aws_route_table" "private_routes" {

    vpc_id = "${aws_vpc.main.id}"
    route {
        cidr_block = "0.0.0.0/0"
        instance_id = "${aws_instance.vpc_nat.id}"
    }

    tags {
        Name = "${var.vpc_name}-Private-Routing"
        VPC = "${var.vpc_name}"
    }

}

# Subnet associations
# Private subnet 1
resource "aws_route_table_association" "private_a1" {

    subnet_id = "${aws_subnet.private_1.id}"
    route_table_id = "${aws_route_table.private_routes.id}"

}

# Subnet associations
# Private subnet 2
resource "aws_route_table_association" "private_a2" {

    subnet_id = "${aws_subnet.private_2.id}"
    route_table_id = "${aws_route_table.private_routes.id}"

}

# Subnet associations
# Private subnet 3
resource "aws_route_table_association" "private_a3" {

    subnet_id = "${aws_subnet.private_3.id}"
    route_table_id = "${aws_route_table.private_routes.id}"

}

####################################
## Route tables: public instances ##
####################################

# Routes through the internet gateway
resource "aws_route_table" "public_routes" {

    vpc_id = "${aws_vpc.main.id}"
    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = "${aws_internet_gateway.gateway.id}"
    }

    tags {
        Name = "${var.vpc_name}-Public-Routing"
        VPC = "${var.vpc_name}"
    }

}

# Subnet associations
# Public subnet 1
resource "aws_route_table_association" "public_a1" {

    subnet_id = "${aws_subnet.public_1.id}"
    route_table_id = "${aws_route_table.public_routes.id}"

}

# Subnet associations
# Public subnet 2
resource "aws_route_table_association" "public_a2" {

    subnet_id = "${aws_subnet.public_2.id}"
    route_table_id = "${aws_route_table.public_routes.id}"

}

# Subnet associations
# Public subnet 3
resource "aws_route_table_association" "public_a3" {

    subnet_id = "${aws_subnet.public_3.id}"
    route_table_id = "${aws_route_table.public_routes.id}"

}

#####################################
## VPC NAT instance security group ##
#####################################

resource "aws_security_group" "vpc_nat" {

    name = "${var.vpc_name}-NAT-Instance"
    description = "Allow outbound internet traffic from private subnet(s)"
    vpc_id = "${aws_vpc.main.id}"

    # Incoming traffic from private instances
    ingress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = [
            "${aws_subnet.private_1.cidr_block}",
            "${aws_subnet.private_2.cidr_block}",
            "${aws_subnet.private_3.cidr_block}"
        ]
    }

    # NAT'ed outgoing traffic (passes through the VPC NAT instance)
    egress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }

    tags {
        Name = "${var.vpc_name}-NAT-Instance"
        VPC = "${var.vpc_name}"
    }

}

######################
## VPC NAT Instance ##
######################

# Import the keypair
resource "aws_key_pair" "nat_key" {

    key_name   = "${var.vpc_name}-nat"
    public_key = "${file("${var.vpc_nat_key_file}")}"

    lifecycle {
        create_before_destroy = true
    }

}

# Create the instance
resource "aws_instance" "vpc_nat" {

    # Requires the internet gateway to be available
    depends_on = ["aws_internet_gateway.gateway"]

    # Place in the first public subnet
    subnet_id = "${aws_subnet.public_1.id}"

    ami = "${lookup(var.vpc_nat_ami, var.vpc_region)}"
    instance_type = "${var.vpc_nat_instance_type}"
    associate_public_ip_address = true
    source_dest_check = false
    vpc_security_group_ids = [
        "${aws_security_group.vpc_nat.id}"
    ]
    monitoring = "${var.vpc_nat_detailed_monitoring}"

    # Key to allow SSH access
    key_name = "${aws_key_pair.nat_key.key_name}"

    tags {
        Name = "${var.vpc_name}-NAT-Instance"
        VPC = "${var.vpc_name}"
    }

}

#############
## Outputs ##
#############

output "vpc_id" {
    value = "${aws_vpc.main.id}"
}

output "vpc_region" {
    value = "${var.vpc_region}"
}

output "vpc_private_subnets" {
    value = "${aws_subnet.private_1.cidr_block},${aws_subnet.private_2.cidr_block},${aws_subnet.private_3.cidr_block}"
}

output "vpc_private_subnet_ids" {
    value = "${aws_subnet.private_1.id},${aws_subnet.private_2.id},${aws_subnet.private_3.id}"
}

output "vpc_public_subnets" {
    value = "${aws_subnet.public_1.cidr_block},${aws_subnet.public_2.cidr_block},${aws_subnet.public_3.cidr_block}"
}

output "vpc_public_subnet_ids" {
    value = "${aws_subnet.public_1.id},${aws_subnet.public_2.id},${aws_subnet.public_3.id}"
}
