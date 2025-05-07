#!/bin/bash

# Verificar se o arquivo de configuração existe
CONFIG_FILE="config.env"
if [ ! -f "$CONFIG_FILE" ]; then
    echo "Erro: Arquivo de configuração $CONFIG_FILE não encontrado!"
    exit 1
fi

# Carregar variáveis do arquivo de configuração
source $CONFIG_FILE

# Verificar se as variáveis obrigatórias foram definidas
if [ -z "$VM_ID" ] || [ -z "$IMAGE_URL" ]; then
    echo "Erro: Variáveis VM_ID e IMAGE_URL são obrigatórias no arquivo de configuração!"
    exit 1
fi

# Verificar se a VM já existe
if qm status $VM_ID >/dev/null 2>&1; then
    echo "Erro: VM com ID $VM_ID já existe!"
    echo "Por favor, altere o ID no arquivo de configuração."
    exit 1
fi

# Verificar se o ID é um número válido entre 100 e 999999
if ! [[ "$VM_ID" =~ ^[0-9]+$ ]] || [ "$VM_ID" -lt 100 ] || [ "$VM_ID" -gt 999999 ]; then
    echo "Erro: ID da VM deve ser um número entre 100 e 999999"
    exit 1
fi

TEMP_DIR="/tmp"
IMAGE_NAME=$(basename $IMAGE_URL)
VM_NAME=$(echo $IMAGE_NAME | sed 's/\.img$//')

echo "Iniciando criação do template Ubuntu com ID: $VM_ID"
echo "Nome da VM será: $VM_NAME"

# Criar diretório temporário e baixar a imagem
cd $TEMP_DIR
echo "Baixando imagem cloud..."
wget $IMAGE_URL

# Verificar se o wget foi bem sucedido
if [ $? -ne 0 ]; then
    echo "Erro ao baixar a imagem!"
    exit 1
fi

# Instalar dependências necessárias
echo "Instalando libguestfs-tools..."
apt install libguestfs-tools -y

# Customizar a imagem
echo "Customizando a imagem..."
virt-customize --add $IMAGE_NAME --install qemu-guest-agent

# Criar VM
echo "Criando VM..."
qm create $VM_ID \
    --name "$VM_NAME" \
    --numa 0 \
    --ostype l26 \
    --cpu cputype=host \
    --cores ${CORES:-4} \
    --sockets ${SOCKETS:-2} \
    --memory ${MEMORY:-6144} \
    --net0 virtio,bridge=${BRIDGE:-vmbr0}

# Importar disco
echo "Importando disco..."
qm importdisk $VM_ID $TEMP_DIR/$IMAGE_NAME ${STORAGE:-local-lvm}

# Configurar VM
echo "Configurando VM..."
qm set $VM_ID --scsihw virtio-scsi-pci --scsi0 ${STORAGE:-local-lvm}:vm-$VM_ID-disk-0
qm set $VM_ID --ide2 ${STORAGE:-local-lvm}:cloudinit
qm set $VM_ID --boot c --bootdisk scsi0
qm set $VM_ID --serial0 socket --vga serial0
qm set $VM_ID --agent enabled=1

# Redimensionar disco
echo "Redimensionando disco..."
qm disk resize $VM_ID scsi0 ${DISK_SIZE:-"+100G"}

# Converter em template
echo "Convertendo em template..."
qm template $VM_ID

echo "Template criado com sucesso!"
echo "ID da VM: $VM_ID"
echo "Nome da VM: $VM_NAME"