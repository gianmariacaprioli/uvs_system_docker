FROM ros:humble-ros-base-jammy

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

ENV ROS_DISTRO=humble
ENV XDG_RUNTIME_DIR=/tmp/runtime-root
ENV QT_X11_NO_MITSHM=1

ARG DEBIAN_FRONTEND=noninteractive

# Installa le utility di sistema.
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
    && rm -rf /var/lib/apt/lists/*

# Configura il repository ufficiale OSRF.
RUN curl -fsSL https://packages.osrfoundation.org/gazebo.gpg \
        -o /usr/share/keyrings/pkgs-osrf-archive-keyring.gpg \
    && source /etc/os-release \
    && echo \
        "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/pkgs-osrf-archive-keyring.gpg] https://packages.osrfoundation.org/gazebo/ubuntu-stable ${UBUNTU_CODENAME} main" \
        > /etc/apt/sources.list.d/gazebo-stable.list

# Installa Gazebo Harmonic e le dipendenze ROS 2.
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        gz-harmonic \
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

# Configura l'identità Git nel container.
RUN git config --global user.name "Gianmaria Caprioli" \
    && git config --global user.email "caprioligianmaria@gmail.com" \
    && git config --global pull.ff only \
    && git config --global fetch.prune true \
    && git config --global push.default simple

# Repository e branch iniziali.
ARG ASV_SIMULATOR_REPOSITORY=https://github.com/gianmariacaprioli/asv_simulator.git
ARG ASV_SIMULATOR_BRANCH=map_generator_feature

ARG VESSEL_SYSTEM_REPOSITORY=https://github.com/gianmariacaprioli/vessel_system.git
ARG VESSEL_SYSTEM_BRANCH=main

# Clona direttamente i branch richiesti.
#
# Non viene utilizzato --single-branch, quindi sarà possibile recuperare e
# selezionare anche gli altri branch remoti.
RUN mkdir -p /root/ros2_ws/src \
    && git clone \
        --branch "${ASV_SIMULATOR_BRANCH}" \
        "${ASV_SIMULATOR_REPOSITORY}" \
        /root/ros2_ws/src/asv_simulator \
    && git clone \
        --branch "${VESSEL_SYSTEM_BRANCH}" \
        "${VESSEL_SYSTEM_REPOSITORY}" \
        /root/ros2_ws/src/vessel_system

COPY docker/entrypoint.sh /ros_entrypoint_workspace.sh

# Compila il workspace e prepara la directory runtime.
RUN source /opt/ros/humble/setup.bash \
    && cd /root/ros2_ws \
    && colcon build \
        --symlink-install \
        --cmake-args -DBUILD_TESTING=OFF \
    && mkdir -p "${XDG_RUNTIME_DIR}" \
    && chmod 700 "${XDG_RUNTIME_DIR}" \
    && chmod +x /ros_entrypoint_workspace.sh

# Configura il comando tkill e il mouse di tmux.
RUN printf '\n%s\n' \
        'unalias tkill 2>/dev/null || true' \
        'unset -f tkill 2>/dev/null || true' \
        "alias tkill='tmux kill-session'" \
        >> /root/.bashrc \
    && printf '%s\n' \
        'set -g mouse on' \
        >> /root/.tmux.conf

WORKDIR /root/ros2_ws

ENTRYPOINT ["/ros_entrypoint_workspace.sh"]
CMD ["bash"]
