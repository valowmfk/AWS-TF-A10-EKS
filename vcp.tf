# VPC
resource "aws_vpc" "cloud-demo" {
  cidr_block = var.vpc_cidr

  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name                                           = "${var.project}-vpc",
    "kubernetes.io/cluster/${var.project}-cluster" = "shared"
  }
}

# Public Subnets
resource "aws_subnet" "public" {
  count                   = var.azs
  vpc_id                  = aws_vpc.cloud-demo.id
  cidr_block              = "10.0.${11 + count.index}.0/24"
  map_public_ip_on_launch = var.mapPublicIP
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  tags = {
    Name                                           = "${var.project}-public-sg"
    "kubernetes.io/cluster/${var.project}-cluster" = "shared"
    "kubernetes.io/role/elb"                       = 1
  }
}

# Private Subnets
resource "aws_subnet" "private" {
  count                   = var.azs
  vpc_id                  = aws_vpc.cloud-demo.id
  cidr_block              = "10.0.${101 + count.index}.0/24"
  map_public_ip_on_launch = var.mapPublicIP
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  tags = {
    Name                                           = "${var.project}-private-sg"
    "kubernetes.io/cluster/${var.project}-cluster" = "shared"
    "kubernetes.io/role/internal-elb"              = 1
  }
}

# Management Subnet
resource "aws_subnet" "mgmt1" {
  vpc_id                  = aws_vpc.cloud-demo.id
  cidr_block              = "10.0.251.0/24"
  map_public_ip_on_launch = var.mapPublicIP
  availability_zone       = data.aws_availability_zones.available.names[0]
  tags = {
    Name = "${var.project}-mgmt-sg"
  }
}
# Internet Gateway
resource "aws_internet_gateway" "cloud-demo" {
  vpc_id = aws_vpc.cloud-demo.id

  tags = {
    "Name" = "${var.project}-igw"
  }

  depends_on = [aws_vpc.cloud-demo]
}

# Route Table(s)
# Route the public subnet traffic through the IGW
resource "aws_route_table" "main" {
  vpc_id = aws_vpc.cloud-demo.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.cloud-demo.id
  }

  tags = {
    Name = "${var.project}-Default-rt"
  }
}

# Route table and subnet associations
resource "aws_route_table_association" "public" {
  count = var.availability_zones_count

  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.main.id
}
resource "aws_route_table_association" "mgmt1" {
  count = var.availability_zones_count

  subnet_id      = aws_subnet.mgmt1.id
  route_table_id = aws_route_table.main.id
}

# NAT Elastic IP
resource "aws_eip" "main" {
  vpc = true

  tags = {
    Name = "${var.project}-ngw-ip"
  }
}
resource "aws_eip" "mgmt1" {
  vpc                       = true
  network_interface         = aws_network_interface.vth-mngt-nic1.id
  associate_with_private_ip = "10.0.251.11"
  depends_on                = [aws_internet_gateway.cloud-demo]
}

resource "aws_eip" "vthunder-vip"{
  vpc                       = true
  network_interface         = aws_network_interface.vth-public-nic1.id
  associate_with_private_ip = "10.0.11.230"
  depends_on                = [aws_internet_gateway.cloud-demo]
}

# NAT Gateway
resource "aws_nat_gateway" "main" {
  allocation_id = aws_eip.main.id
  subnet_id     = aws_subnet.public[0].id

  tags = {
    Name = "${var.project}-ngw"
  }
}
resource "aws_network_interface" "vth-mngt-nic1" {
  subnet_id = aws_subnet.mgmt1.id
  private_ips     = ["10.0.251.11"]
  security_groups = [aws_security_group.allow_web.id]
}

resource "aws_network_interface" "vth-public-nic1" {
  subnet_id = aws_subnet.public[0].id
  security_groups = [aws_security_group.public_sg.id]
  source_dest_check = "false"
  private_ips_count = 2
  private_ips = ["10.0.11.16", "10.0.11.230"] # Second listed IP is the VIP IP - Elastic IPs are mapped to this IP
}
resource "aws_network_interface" "vth-private-nic1" {
  subnet_id = aws_subnet.private[0].id
  security_groups = [aws_security_group.data_plane_sg.id]
  source_dest_check = "false"
}

# Add route to route table
resource "aws_route" "main" {
  route_table_id         = aws_vpc.cloud-demo.default_route_table_id
  nat_gateway_id         = aws_nat_gateway.main.id
  destination_cidr_block = "0.0.0.0/0"
}

# Security group for public subnet
resource "aws_security_group" "public_sg" {
  name   = "${var.project}-Public-sg"
  vpc_id = aws_vpc.cloud-demo.id

  tags = {
    Name = "${var.project}-Public-sg"
  }
}

# Security group traffic rules
resource "aws_security_group_rule" "sg_ingress_public_443" {
  security_group_id = aws_security_group.public_sg.id
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "sg_ingress_public_80" {
  security_group_id = aws_security_group.public_sg.id
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "sg_egress_public" {
  security_group_id = aws_security_group.public_sg.id
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
}

# Security group for data plane
resource "aws_security_group" "data_plane_sg" {
  name   = "${var.project}-Worker-sg"
  vpc_id = aws_vpc.cloud-demo.id

  tags = {
    Name = "${var.project}-Worker-sg"
  }
}

# Security group traffic rules
resource "aws_security_group_rule" "nodes" {
  description       = "Allow nodes to communicate with each other"
  security_group_id = aws_security_group.data_plane_sg.id
  type              = "ingress"
  from_port         = 0
  to_port           = 65535
  protocol          = "-1"
  cidr_blocks       = flatten([cidrsubnet(var.vpc_cidr, var.subnet_cidr_bits, 0), cidrsubnet(var.vpc_cidr, var.subnet_cidr_bits, 1), cidrsubnet(var.vpc_cidr, var.subnet_cidr_bits, 2), cidrsubnet(var.vpc_cidr, var.subnet_cidr_bits, 3)])
}

resource "aws_security_group_rule" "nodes_inbound" {
  description       = "Allow worker Kubelets and pods to receive communication from the cluster control plane"
  security_group_id = aws_security_group.data_plane_sg.id
  type              = "ingress"
  from_port         = 1025
  to_port           = 65535
  protocol          = "tcp"
  cidr_blocks       = flatten([cidrsubnet(var.vpc_cidr, var.subnet_cidr_bits, 2), cidrsubnet(var.vpc_cidr, var.subnet_cidr_bits, 3)])
  # cidr_blocks       = flatten([var.private_subnet_cidr_blocks])
}

resource "aws_security_group_rule" "node_outbound" {
  security_group_id = aws_security_group.data_plane_sg.id
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
}

# Security group for control plane
resource "aws_security_group" "control_plane_sg" {
  name   = "${var.project}-ControlPlane-sg"
  vpc_id = aws_vpc.cloud-demo.id

  tags = {
    Name = "${var.project}-ControlPlane-sg"
  }
}

# Security group traffic rules
resource "aws_security_group_rule" "control_plane_inbound" {
  security_group_id = aws_security_group.control_plane_sg.id
  type              = "ingress"
  from_port         = 0
  to_port           = 65535
  protocol          = "tcp"
  cidr_blocks       = flatten([cidrsubnet(var.vpc_cidr, var.subnet_cidr_bits, 0), cidrsubnet(var.vpc_cidr, var.subnet_cidr_bits, 1), cidrsubnet(var.vpc_cidr, var.subnet_cidr_bits, 2), cidrsubnet(var.vpc_cidr, var.subnet_cidr_bits, 3)])
}

resource "aws_security_group_rule" "control_plane_outbound" {
  security_group_id = aws_security_group.control_plane_sg.id
  type              = "egress"
  from_port         = 0
  to_port           = 65535
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
}
resource "aws_security_group" "allow_web" {
  name        = "allow_web_traffic"
  description = "Allow web inbound traffic"
  vpc_id      = aws_vpc.cloud-demo.id

  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 8
    to_port     = 0
    protocol    = "icmp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "allow_web"
  }
}