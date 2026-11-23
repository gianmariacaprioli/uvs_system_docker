#!/bin/bash

set -e

CONTAINER_NAME="uvs_system"
IMAGE_NAME="usv_system_docker:v3"

HOST_VESSEL_WS="${HOME}/vessel_ws"
CONTAINER_VESSEL_WS="/root/vessel_ws"

# Create the shared workspace on the host if it does not exist
mkdir -p "${HOST_VESSEL_WS}"

# Allow Docker containers to access the host X server
if command -v xhost >/dev/null 2>&1; then
    xhost +local:docker >/dev/null 2>&1 || true
fi


# =========================================================
# If the container already exists
# =========================================================

if docker ps -a --format '{{.Names}}' | grep -qx "${CONTAINER_NAME}"; then

    # Start it if it is stopped
    if ! docker ps --format '{{.Names}}' | grep -qx "${CONTAINER_NAME}"; then
        echo "Starting existing container '${CONTAINER_NAME}'..."
        docker start "${CONTAINER_NAME}"
    fi

    echo "Opening shell inside '${CONTAINER_NAME}'..."
    docker exec -it "${CONTAINER_NAME}" bash

    exit 0
fi


# =========================================================
# Check that the image exists
# =========================================================

if ! docker image inspect "${IMAGE_NAME}" >/dev/null 2>&1; then
    echo "ERROR: Docker image '${IMAGE_NAME}' was not found."
    echo
    docker images
    exit 1
fi


echo "Creating persistent container '${CONTAINER_NAME}'..."


# =========================================================
# Docker arguments
# =========================================================

DOCKER_ARGS=(

    --name "${CONTAINER_NAME}"

    # Run container in background
    -d

    # Full hardware/device access
    --privileged

    # Share host network
    --network host

    # Share IPC namespace
    --ipc host

    # Share PID namespace
    --pid host

    # GUI support
    -e DISPLAY="${DISPLAY}"
    -e QT_X11_NO_MITSHM=1

    # X11 socket
    -v /tmp/.X11-unix:/tmp/.X11-unix:rw

    # Shared workspace
    -v "${HOST_VESSEL_WS}:${CONTAINER_VESSEL_WS}"

    # Host devices:
    # USB, serial, keyboard, mouse, joystick, cameras, etc.
    -v /dev:/dev
)


# =========================================================
# XDG runtime / audio / Wayland
# =========================================================

if [ -n "${XDG_RUNTIME_DIR}" ] && [ -d "${XDG_RUNTIME_DIR}" ]; then

    DOCKER_ARGS+=(
        -e XDG_RUNTIME_DIR="${XDG_RUNTIME_DIR}"
        -v "${XDG_RUNTIME_DIR}:${XDG_RUNTIME_DIR}"
    )

fi


# =========================================================
# PulseAudio
# =========================================================

if [ -n "${XDG_RUNTIME_DIR}" ] && \
   [ -S "${XDG_RUNTIME_DIR}/pulse/native" ]; then

    DOCKER_ARGS+=(
        -e PULSE_SERVER="unix:${XDG_RUNTIME_DIR}/pulse/native"
    )

fi


# =========================================================
# ALSA audio
# =========================================================

if [ -d /dev/snd ]; then
    DOCKER_ARGS+=(
        --device /dev/snd
    )
fi


# =========================================================
# NVIDIA GPU
# =========================================================

if command -v nvidia-smi >/dev/null 2>&1; then

    echo "NVIDIA GPU detected."

    DOCKER_ARGS+=(
        --gpus all
        -e NVIDIA_VISIBLE_DEVICES=all
        -e NVIDIA_DRIVER_CAPABILITIES=all
    )

fi


# =========================================================
# Create container
# =========================================================

docker run \
    "${DOCKER_ARGS[@]}" \
    "${IMAGE_NAME}" \
    tail -f /dev/null


# =========================================================
# Enter container
# =========================================================

echo "Container '${CONTAINER_NAME}' created and running."
echo "Opening shell..."

docker exec -it "${CONTAINER_NAME}" bash
