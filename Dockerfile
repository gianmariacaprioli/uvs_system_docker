FROM ros:humble-ros-base-jammy

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

ENV ROS_DISTRO=humble
ENV XDG_RUNTIME_DIR=/tmp/runtime-root
ENV QT_X11_NO_MITSHM=1

ARG DEBIAN_FRONTEND=noninteractive

# Gazebo Harmonic packages for ROS 2 Humble are published by the OSRF Gazebo
# repository. Generic ros-humble-ros-gz packages are intentionally not
# installed because on Humble they target Gazebo Fortress.
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        ca-certificates \
        curl \
        git \
        gnupg \
        libgl1-mesa-dri \
        python3-colcon-common-extensions \
        python3-numpy \
        python3-pandas \
        python3-scipy \
        tmux \
    && curl -fsSL https://packages.osrfoundation.org/gazebo.gpg \
        -o /usr/share/keyrings/pkgs-osrf-archive-keyring.gpg \
    && source /etc/os-release \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/pkgs-osrf-archive-keyring.gpg] https://packages.osrfoundation.org/gazebo/ubuntu-stable ${UBUNTU_CODENAME} main" \
        > /etc/apt/sources.list.d/gazebo-stable.list \
    && apt-get update \
    && apt-get install -y --no-install-recommends \
        libgz-physics7-dartsim \
        libgz-rendering8-ogre1 \
        libgz-rendering8-ogre2 \
        ros-humble-ament-index-python \
        ros-humble-geometry-msgs \
        ros-humble-launch \
        ros-humble-launch-ros \
        ros-humble-nav-msgs \
        ros-humble-nav2-lifecycle-manager \
        ros-humble-nav2-map-server \
        ros-humble-pointcloud-to-laserscan \
        ros-humble-robot-state-publisher \
        ros-humble-ros-gzharmonic \
        ros-humble-rosgraph-msgs \
        ros-humble-rviz2 \
        ros-humble-sensor-msgs \
        ros-humble-sensor-msgs-py \
        ros-humble-std-msgs \
        ros-humble-tf2-ros \
    && rm -rf /var/lib/apt/lists/*

ARG ASV_SIMULATOR_REPOSITORY=https://github.com/gianmariacaprioli/asv_simulator.git
ARG ASV_SIMULATOR_REF=f34f9d440fe1f3420de7817ffc5e1bc21949e88d
ARG VESSEL_SYSTEM_REPOSITORY=https://github.com/gianmariacaprioli/vessel_system.git
ARG VESSEL_SYSTEM_REF=74ca14e8371b7ee842c443eb7074dc53e77975e9

RUN mkdir -p /root/ros2_ws/src \
    && git clone "${ASV_SIMULATOR_REPOSITORY}" /root/ros2_ws/src/asv_simulator \
    && git -C /root/ros2_ws/src/asv_simulator checkout "${ASV_SIMULATOR_REF}" \
    && git clone "${VESSEL_SYSTEM_REPOSITORY}" /root/ros2_ws/src/vessel_system \
    && git -C /root/ros2_ws/src/vessel_system checkout "${VESSEL_SYSTEM_REF}"

COPY docker/entrypoint.sh /ros_entrypoint_workspace.sh

RUN source /opt/ros/humble/setup.bash \
    && cd /root/ros2_ws \
    && colcon build --symlink-install --cmake-args -DBUILD_TESTING=OFF \
    && mkdir -p "${XDG_RUNTIME_DIR}" \
    && chmod 700 "${XDG_RUNTIME_DIR}" \
    && chmod +x /ros_entrypoint_workspace.sh

WORKDIR /root/ros2_ws

ENTRYPOINT ["/ros_entrypoint_workspace.sh"]
CMD ["bash"]
