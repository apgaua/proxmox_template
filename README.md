# Proxmox_template
Created this repository to host scripts to help me maintain, create and delete **Proxmox** template files.

## Files

In this repository there's 3 important files, create_template.sh, delete_template.sh and config.env

### Description
| File | Description | Usage | 
|--|--|--|
| config.env | Template with values that are needed when running create_template.sh | Edit this file with your desired values, or copy it to a new file and edit it. |
| create_template.sh | Script that create Proxmox templates using created .env file| Execute ./create_template.sh passing respective .env file as a parameter <br> `./create_template.sh config.env`|
| delete_template.sh | Script that delete Proxmox template passing respective ID | Delete template ID 9999 <br> `./delete_template.sh 9999`|

## Usage
#### Template creation
- Clone this repository using your proxmox terminal.
- Edit config.env variables or copy values to a new file and edit them.
- Set create_template.sh as executable:`chmod a+x create_template.sh`
- Run create_template passing your .env file as a parameter: `./create_template.sh config.env`

#### Template deletion
- Find the ID of the template that you want to delete.
- Set delete_template.sh as executable: `chmod a+x delete_template.sh`
- Run delete_template.sh passing the ID as a parameter: `./delete_template.sh ID`
>To delete template ID 9999, run `./delete_template.sh 9999`

## Cloud Images repositories
These are one of hundreds of linux distro that support cloud images.
| Distribution | URL |
|--|--|
| Ubuntu | https://cloud-images.ubuntu.com/releases/ |
| Debian | https://cdimage.debian.org/images/cloud/ |

### Cloud Image URL
| Version | URL |
|--|--|
| Ubuntu 25.04 | https://cloud-images.ubuntu.com/releases/plucky/release/ubuntu-25.04-server-cloudimg-amd64.img |
| Ubuntu 24.10 | https://cloud-images.ubuntu.com/releases/oracular/release/ubuntu-24.10-server-cloudimg-amd64.img |

Use the URL above to set **IMAGE_URL** variable inside the **.env file**.

## TO-DO
- Organize readme file with repositories from more distros.