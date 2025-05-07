#!/bin/bash

# Was ID provided?
if [ $# -eq 0 ]; then
    echo "Use: $0 <VM_ID>"
    echo "Exemple: $0 9900"
    exit 1
fi

VM_ID="$1"

# Is ID a valid number?
if ! [[ "$VM_ID" =~ ^[0-9]+$ ]] || [ "$VM_ID" -lt 9900 ] || [ "$VM_ID" -gt 9999 ]; then
    echo "Error: VM ID must be a number between 9900 and 9999!"
    exit 1
fi

# Template with provided ID exists?
if ! qm status $VM_ID >/dev/null 2>&1; then
    echo "Error: $VM_ID ID Template does not exist!"
    exit 1
fi

# Is it a template?
if ! qm config $VM_ID | grep -q "template: 1"; then
    echo "Error: $VM_ID VM is not a template!"
    exit 1
fi

# Get template name
VM_NAME=$(qm config $VM_ID | grep name | cut -d':' -f2 | tr -d ' ')

echo "You're about to delete the following template:"
echo "ID: $VM_ID"
echo "Name: $VM_NAME"
echo
read -p "Are you sure you want to delete this template? (Y/N) " -n 1 -r
echo

if [[ ! $REPLY =~ ^[Ss]$ ]]; then
    echo "Operation canceled!"
    exit 1
fi

# Delete template and associated files
echo "Destroying $VM_NAME template (ID: $VM_ID)..."
qm destroy $VM_ID --purge

if [ $? -eq 0 ]; then
    echo "Template sucessfully deleted!"
else
    echo "Error deleting template!"
    exit 1
fi