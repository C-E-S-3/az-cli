#!/usr/bin/bash
#
#
#
# ADMIN_USERNAME=
SSH_KEYFILE=/home/admin/.ssh/azure_id_rsa.pub
LOCATION="eastus"
OS_IMAGE="Ubuntu2204"
VM_SIZE="Basic_B1ls"
ZSCALER_IPS="147.161.174.0/23 185.46.212.0/23 147.161.172.0/23 165.225.240.0/23 147.161.232.0/23 147.161.234.0/23 147.161.224.0/23 147.161.226.0/23 147.161.228.0/23 147.161.230.0/23 165.225.12.0/23 196.23.154.96/27 165.225.194.0/23 147.161.160.0/23 165.225.72.0/22 165.225.26.0/23 147.161.164.0/23 197.98.201.0/24 147.161.162.0/23 154.113.23.0/24 165.225.80.0/22 147.161.166.0/23 165.225.16.0/23 165.225.92.0/23 165.225.196.0/23 165.225.198.0/23 147.161.178.0/23 147.161.180.0/23 147.161.182.0/23 165.225.202.0/23 165.225.66.0/24 165.225.90.0/23 147.161.176.0/23 147.161.168.0/23 147.161.170.0/23 213.52.102.0/24 165.225.76.0/23 165.225.20.0/23 147.161.184.0/23 165.225.204.0/23 165.225.192.0/23 94.188.139.64/26 165.225.200.0/23 165.225.206.0/23 165.225.94.0/23 192.127.94.77 192.127.94.7 104.129.204.0/23 136.226.2.0/23 104.129.206.0/23 136.226.54.0/23 136.226.56.0/23 136.226.58.0/23 136.226.60.0/23 136.226.62.0/23 136.226.64.0/23 136.226.70.0/23 136.226.72.0/23 136.226.74.0/23 165.225.56.0/22 104.129.196.0/23 165.225.60.0/22 128.177.125.0/24 165.225.0.0/23 137.83.154.0/24 165.225.2.0/24 136.226.66.0/23 136.226.68.0/23 165.225.34.0/23 165.225.216.0/23 165.225.32.0/23 165.225.36.0/23 165.225.10.0/23 104.129.198.0/23 136.226.0.0/23 165.225.222.0/23 165.225.212.0/23 165.225.38.0/23 165.225.220.0/23 165.225.218.0/23 104.129.192.0/23 165.225.242.0/23 64.215.22.0/24 165.225.214.0/23 147.161.128.0/23 165.225.50.0/23 165.225.14.0/23 165.225.208.0/23 165.225.210.0/23 104.129.194.0/23 136.226.48.0/23 136.226.52.0/23 165.225.8.0/23 136.226.50.0/23 124.248.141.0/24 211.144.19.0/24 165.225.104.0/24 165.225.122.0/23 165.225.116.0/23 165.225.234.0/23 112.137.170.0/24 165.225.98.0/24 165.225.226.0/23 165.225.106.0/23 165.225.120.0/23 165.225.124.0/23 147.161.192.0/23 165.225.228.0/23 1.234.57.0/24 58.220.95.0/24 165.225.112.0/23 165.225.230.0/23 175.45.116.0/24 165.225.114.0/23 165.225.232.0/23 165.225.102.0/24 221.122.91.0/24 165.225.110.0/23 165.225.96.0/23"

#read -p "VMName: " NAME
#read -p "Admin: " ADMIN_USERNAME

BASENAME=$PREFIX-$NAME
#echo $BASENAME
RESOURCEGROUPNAME=$BASENAME-group
# USAGE:
# create_rg $RESOURCEGROUPNAME $LOCATION
create_rg() {
	if [ $(az group exists --name $1) = false ]; then
		echo "[0]Creating $1..."
		az group create --name $1 --location $2 1>/dev/null
		echo "[-]Waiting for $1 to be created..."
		az group wait --name $1 --created
		echo "[X]$1 created..."
	else
		echo "Resource Group $1 Exists..."
		echo "Continuing..."
	fi
}

VNETNAME=$BASENAME-vnet
SUBNETNAME=$BASENAME-subnet
# USAGE
# create_vnet $RESOURCEGROUPNAME $VNETNAME $SUBNETNAME
create_vnet() {
	echo "[0]Creating $2..."
	az network vnet create \
		--resource-group $1 \
		--name $2 \
		--subnet-name $3 1>/dev/null
	# --address-prefix 10.0.x.0/24 \
	# --subnet-prefix 10.0.x.0/24

	# az network vnet wait --created --name $VNETNAME
	echo "[X]$2 created..."
}

PUBLICIPNAME=$BASENAME-ip
# USAGE
# create_public_ip $RESOURCEGROUPNAME $PUBLICIPNAME
create_public_ip() {
	echo "[0]Creating $2 ..."
	az network public-ip create \
		--resource-group $1 \
		--name $2 \
		--sku Basic 1>/dev/null
	# --dns-name $DNSNAME

	echo "[X]$2 created..."

	# az network public-ip wait --created --name $PUBLICIPNAME
}

FRONTENDIP_NAME=$BASENAME-frontend-ip
# USAGE
# create_public_ip $RESOURCEGROUPNAME $PUBLICIPNAME
create_public_ip_lb() {
	echo "[0]Creating $2..."
	az network public-ip create \
		--resource-group $1 \
		--name $2 \
		--sku Standard 1>/dev/null
	# --dns-name $DNSNAME

	echo "[X]$2 created.."

	# az network public-ip wait --created --name $PUBLICIPNAME
}

NSGNAME=$BASENAME-nsg
# USAGE
# create_nsg $RESOURCEGROUPNAME $NSGNAME
create_nsg() {
	echo "[0]Creating $2..."
	az network nsg create \
		--resource-group $1 \
		--name $2 1>/dev/null

	# az network nsg wait --created --name $NSGNAME
	echo "[0]Created $2 ..."
}

NSGRULENAME=AllowSSHInbound
# USAGE
# create_nsg_SSH_rule $RESOURCEGROUPNAME $NSGNAME $NSGRULENAME $ZSCALER_IPS
create_nsg_SSH_rule() {
	echo "[0]Creating $2..."
	az network nsg rule create \
		--resource-group $1 \
		--nsg-name $2 \
		--name $3 \
		--protocol tcp \
		--priority 1011 \
		--destination-port-range 22 \
		--source-address-prefixes $4 \
		--access allow 1>/dev/null

	# az network nsg rule wait --created --name $NSGRULENAME
	echo "[X]$2 created..."
}

NICNAME=$BASENAME-nic
# USAGE
# create_nic $RESOURCEGROUPNAME $NICNAME $VNETNAME $SUBNETNAME
create_nic_private() {
	echo "[0]Creating Private NIC - $2..."
	az network nic create \
		--resource-group $1 \
		--name $2 \
		--vnet-name $3 \
		--subnet $4 1>/dev/null
	#--public-ip-address $5
	#--network-security-group $6 1>/dev/null

	# az network nic wait --created --name $NICNAME
	echo "[X]$2 created..."
}
NICNAME=$BASENAME-nic-public
# USAGE
# create_nic $RESOURCEGROUPNAME $NICNAME $VNETNAME $SUBNETNAME $PUBLICIPNAME $NSGNAME
create_nic_public() {
	echo "[0]Creating Public NIC - $2..."
	az network nic create \
		--resource-group $1 \
		--name $2 \
		--vnet-name $3 \
		--subnet $4 \
		--public-ip-address $5 1>/dev/null
	#--network-security-group $6 1>/dev/null

	# az network nic wait --created --name $NICNAME
	echo "[X]$2 created..."
}

VMNAME=$BASENAME-VM0
# USAGE
# create_vm $RESOURCEGROUPNAME $VMNAME $LOCATION $OS_IMAGE $VM_SIZE $NICNAME $ADMIN_USERNAME $SSH_KEYFILE
create_vm() {
	#if [ $(az vm show --resource-group $1 --name $2) = false ]; then
	echo "[0]Creating $2..."
	az vm create \
		--resource-group $1 \
		--location $3 \
		--name $2 \
		--image $4 \
		--size $5 \
		--nics $6 \
		--admin-username $7 \
		--ssh-key-values $8 1>/dev/null
	# --availability-set $AV_SET-as \

	# az vm wait --created --name $VMNAME --resource-group $RESOURCEGROUPNAME
	echo "[X]$2 now created..."
	# else
	# 	echo "[X]VM Already Exists..."
	# fi
}

HEALTHPROBENAME=$BASENAME-HealthProbe
# USAGE
# create_health_probe $RESOURCEGROUPNAME $LOADBALANCERNAME $HEALTHPROBENAME $PROBEPORTNUMBER
create_health_probe() {
	echo "[0]Creating $3..."
	az network lb probe create \
		--resource-group $1 \
		--lb-name $2 \
		--name $3 \
		--protocol tcp \
		--port $PROBEPORTNUMBER 1>/dev/null

	echo "[X]$3 now created..."
}

LOADBALANCERNAME=$BASENAME-lb
FRONTENDIPNAME=$PUBLICIPNAME-front
BACKENDIPNAME=$PUBLICIPNAME-back
# USAGE
# create_loadbalancer $RESOURCEGROUPNAME $LOADBALANCERNAME $PUBLICIPNAME $FRONTENDIPNAME $BACKENDPOOLNAME
create_loadbalancer() {
	echo "[0]Creating $2..."
	az network lb create \
		--resource-group $1 \
		--name $2 \
		--sku Basic \
		--public-ip-address $3 \
		--frontend-ip-name $4 \
		--backend-pool-name $5 1>/dev/null

	echo "[X]$2 now created..."
}

# USAGE
# create_loadbalancer_rule $RESOURCEGROUPNAME $LOADBALANCERNAME $LOADBALANCERRULE $FRONTENDIPNAME $HEALTHPROBENAME
create_loadbalancer_rule() {
	echo "[0]Creating $3..."
	az network lb rule create \
		--resource-group $1 \
		--lb-name $2 \
		--name $3 \
		--protocol tcp \
		--frontend-port 22 \
		--backend-port 22 \
		--frontend-ip-name $4 \
		--probe-name $5 \
		--disable-outbound-snat true \
		--idle-timeout 15 \
		--enable-tcp-reset true \
		--backend-pool-name $5 1>/dev/null
}

# USAGE
# create_backend_pool $RESOURCEGROUPNAME $BACKENDIPNAME $NICNAME $LOADBALANCERNAME $IPCONFIGNAME
create_backend_pool() {
	echo "[0]Creating $2..."
	az network nic ip-config address-pool add \
		--resource-group $1 \
		--address-pool $2 \
		--nic-name $3 \
		--ip-config-name $5 \
		--lb-name $4 1>/dev/null
}

NATGATEWAYNAME=$BASENAME-nat
# USAGE
# create_nat_gateway $RESOURCEGROUPNAME $NATGATEWAYNAME $NATGATEWAYIPNAME
create_nat_gateway() {
	echo "[0]Creating $2..."
	az network nat gateway create \
		--resource-group $1 \
		--name $2 \
		--public-ip-addresses $3 \
		--idle-timeout 10
	--sku Basic 1>/dev/null
}

# USAGE
# add_gateway_vnet $RESOURCEGROUPNAME $VNETNAME $SUBNETNAME $NATGATEWAYNAME
add_gateway_vnet() {
	echo "[0]Adding $4 to $2..."
	az network vnet subnet update \
		--resource-group $1 \
		--vnet-name $2 \
		--name $3 \
		--nat-gateway $4 1>/dev/null
	echo "[X]$4 added to $2..."
}

# USAGE
# add_nsg_vnet $RESOURCEGROUPNAME $VNETNAME $SUBNETNAME $NSGNAME
add_nsg_vnet() {
	echo "[0]Adding $4 to $2..."
	az network vnet subnet update \
		--resource-group $1 \
		--vnet-name $2 \
		--name $3 \
		--network-security-group $4 1>/dev/null
	echo "[X]$3 added to $2..."
}

# USAGE
# create_inbound_nat_rule_nic $RESOURCEGROUPNAME $LOADBALANCERNAME $NATRULENAME $FRONTENDIPNAME $FRONTENDPORT $BACKENDPORT
create_inbound_nat_rule_nic() {
	echo "[0]Creating Inbound NAT Rule: $3"
	az network lb inbound-nat-rule create \
		--resource-group $1 \
		--lb-name $2 \
		--name $3 \
		--frontend-ip-name $4 \
		--frontend-port $5 \
		--backend-port $6 \
		--protocol Tcp
	echo "[X]Created $3..."
}

# USAGE
# add_inbound_nat_rule_lb $RESOURCEGROUPNAME $NATRULENAME $NICNAME $LOADBALANCERNAME $IPCONFIGNAME
add_inbound_nat_rule_lb() {
	echo "[0]Adding $2 to $3..."
	az network nic ip-config inbound-nat-rule add \
		--resource-group $1 \
		--inbound-nat-rule $2 \
		--nic-name $3 \
		--lb-name $4 \
		--ip-config-name $5
	echo "[X]Added $2 to $3..."
}
