#!/bin/bash

CONFIG_FILE="$1"

# Does config file exists?
if [ ! -f "$CONFIG_FILE" ]; then
    echo "Error: Config file $CONFIG_FILE not found!"
    exit 1
fi

# Load config file variables
source $CONFIG_FILE

# Verify variables
if [ -z "$VM_ID" ] || [ -z "$IMAGE_URL" ]; then
    echo "Error: VM_ID and IMAGE_URL variables need to be set!"
    exit 1
fi

# Does VM exists?
if qm status $VM_ID >/dev/null 2>&1; then
    echo "Error: VM with $VM_ID ID already exists!"
    echo "Please use another ID number."
    exit 1
fi

# Is ID valid?
if ! [[ "$VM_ID" =~ ^[0-9]+$ ]] || [ "$VM_ID" -lt 9900 ] || [ "$VM_ID" -gt 9999 ]; then
    echo "Error: VM ID must be a number between 9900 and 9999!"
    exit 1
fi

TEMP_DIR="/tmp"
IMAGE_NAME=$(basename $IMAGE_URL)
VM_NAME=$(echo $IMAGE_NAME | sed 's/\.img$//')

echo "Creating template with ID: $VM_ID"
echo "Name of template will be: $VM_NAME"

# Download cloud image
cd $TEMP_DIR
echo "Getting cloud image..."
wget $IMAGE_URL

# wget executed properly?
if [ $? -ne 0 ]; then
    echo "Error downloading image!"
    exit 1
fi

# Install dependencies
echo "Installing libguestfs-tools..."
apt install libguestfs-tools -y

# Customize cloud init image
echo "Customizing..."
virt-customize --add $IMAGE_NAME --install qemu-guest-agent

# Create VM
echo "VM creation in progress..."
qm create $VM_ID \
    --name "$VM_NAME" \
    --numa 0 \
    --ostype l26 \
    --cpu cputype=host \
    --cores ${CORES:-4} \
    --sockets ${SOCKETS:-2} \
    --memory ${MEMORY:-6144} \
    --net0 virtio,bridge=${BRIDGE:-vmbr0} \
    --description "
    Name: $VM_NAME
    Created by: $CREATOR
    Creation date: $CREATION_DATE
    VM ID: $VM_ID
    $DESCRIPTON
    "

# VM Disc import
echo "Importing disk..."
qm importdisk $VM_ID $TEMP_DIR/$IMAGE_NAME ${STORAGE:-local-lvm}

# VM Configuration
echo "Configuring VM..."
qm set $VM_ID --scsihw virtio-scsi-pci --scsi0 ${STORAGE:-local-lvm}:vm-$VM_ID-disk-0
qm set $VM_ID --ide2 ${STORAGE:-local-lvm}:cloudinit
qm set $VM_ID --boot c --bootdisk scsi0
qm set $VM_ID --serial0 socket --vga serial0
qm set $VM_ID --agent enabled=1

# Disk resize
echo "Disk resize..."
qm disk resize $VM_ID scsi0 ${DISK_SIZE:-"+100G"}

# Template conversion
echo "Convert VM as Template..."
qm template $VM_ID

echo "Template created successfully!"
echo "VM ID: $VM_ID"
echo "VM Name: $VM_NAME"