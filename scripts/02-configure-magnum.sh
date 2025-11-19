#!/bin/bash
# 02-configure-magnum.sh
# This script configures OpenStack Magnum to be ready for Kubernetes cluster creation.
# It is executed on the 'controller' node after OpenStack is installed.

# --- Preamble ---
set -ex # Exit on error, print commands
LOG_FILE="/tmp/configure-magnum.log"
exec > >(tee -a ${LOG_FILE}) 2>&1

echo "Starting Magnum Configuration..."

# --- Source OpenStack Credentials ---
# The DevStack installation creates a file with the necessary environment
# variables to use the OpenStack command-line clients as the 'admin' user.[34]
source /opt/devstack/openrc admin admin

# Wait for services to be fully available.
sleep 30

# --- Dynamically Find a Suitable Image ---
echo "Searching for a suitable Fedora CoreOS image in Glance..."
K8S_IMAGE_NAME=$(openstack image list -f value -c Name | grep 'fedora-coreos' | head -n 1)

# If no Fedora CoreOS image is found, download and upload one.
if [[ -z "$K8S_IMAGE_NAME" ]]; then
    if openstack image show fedora-coreos-magnum >/dev/null 2>&1; then
        K8S_IMAGE_NAME="fedora-coreos-magnum"
        echo "Using pre-existing image: $K8S_IMAGE_NAME"
    else
        echo "No suitable image found. Downloading Fedora CoreOS for Magnum..."
        FCOS_VERSION="39.20231123.3.0"
        FCOS_BASENAME="fedora-coreos-${FCOS_VERSION}-openstack.x86_64.qcow2"
        FCOS_URL="https://builds.coreos.fedoraproject.org/prod/streams/stable/builds/${FCOS_VERSION}/x86_64/${FCOS_BASENAME}.xz"
        WORKDIR="/tmp/magnum-images"
        mkdir -p "${WORKDIR}"
        curl -L --retry 5 --retry-delay 5 -o "${WORKDIR}/${FCOS_BASENAME}.xz" "${FCOS_URL}"
        xz -d -f "${WORKDIR}/${FCOS_BASENAME}.xz"
        openstack image create fedora-coreos-magnum \
            --disk-format qcow2 \
            --container-format bare \
            --public \
            --file "${WORKDIR}/${FCOS_BASENAME}"
        K8S_IMAGE_NAME="fedora-coreos-magnum"
        echo "Uploaded image: ${K8S_IMAGE_NAME}"
    fi
else
    echo "Found image: '$K8S_IMAGE_NAME'. This will be used for the cluster template."
fi

# --- Ensure a keypair exists for Magnum ---
KEYPAIR_NAME="${MAGNUM_KEYPAIR_NAME:-magnum-default}"
if ! openstack keypair show "${KEYPAIR_NAME}" >/dev/null 2>&1; then
    echo "Creating keypair '${KEYPAIR_NAME}' for Magnum..."
    mkdir -p /root/.ssh
    ssh-keygen -q -t rsa -N "" -f "/root/.ssh/${KEYPAIR_NAME}"
    chmod 600 "/root/.ssh/${KEYPAIR_NAME}"
    openstack keypair create --public-key "/root/.ssh/${KEYPAIR_NAME}.pub" "${KEYPAIR_NAME}"
else
    echo "Keypair '${KEYPAIR_NAME}' already exists."
fi

# --- Create Magnum Cluster Template ---
# A Cluster Template defines the parameters for creating a Kubernetes cluster.[29]
# This allows for consistent cluster deployments.
TEMPLATE_NAME="k8s-default-template"
if openstack coe cluster template show "${TEMPLATE_NAME}" >/dev/null 2>&1; then
    echo "Cluster template '${TEMPLATE_NAME}' already exists. Skipping creation."
else
    echo "Creating Magnum Cluster Template for Kubernetes..."
    openstack coe cluster template create "${TEMPLATE_NAME}" \
        --image "$K8S_IMAGE_NAME" \
        --keypair "${KEYPAIR_NAME}" \
        --external-network public \
        --dns-nameserver 8.8.8.8 \
        --master-flavor m1.small \
        --flavor m1.small \
        --docker-volume-size 20 \
        --network-driver calico \
        --coe kubernetes
fi

# --- Verification ---
# List the created cluster templates to confirm success.
echo "Verifying Cluster Template creation..."
openstack coe cluster template list

echo "Magnum Configuration Complete. The platform is ready to create Kubernetes clusters."
