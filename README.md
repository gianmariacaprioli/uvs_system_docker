# UVS System Docker

This repository builds the `asv_simulator` and `vessel_system` repositories in
a single ROS 2 workspace. The image uses ROS 2 Humble with Gazebo Harmonic
(Gazebo Sim 8) and the matching `ros_gzharmonic` bridge.

Gazebo Fortress packages are intentionally not installed.

## Build

```bash
docker build -t usv-uav-harmonic .
```

The Dockerfile defaults to the two commits that were tested together. A
different commit, tag, branch, or repository can be selected at build time:

```bash
docker build \
  --build-arg ASV_SIMULATOR_REF=map_generator_feature \
  --build-arg VESSEL_SYSTEM_REF=main \
  -t usv-uav-harmonic .
```

## Run with X11

Allow the container root user to connect to the current X server:

```bash
xhost +si:localuser:root
```

Start the container with host networking so ROS 2 DDS and Gazebo Transport can
use their local multicast sockets:

```bash
docker run --rm -it \
  --network host \
  --ipc host \
  -e DISPLAY \
  -v /tmp/.X11-unix:/tmp/.X11-unix:rw \
  usv-uav-harmonic
```

Inside the container, start only the simulation with:

```bash
ros2 launch asv_simulator sim.launch.py
```

To start the simulation and both vehicle controllers:

```bash
/root/ros2_ws/src/vessel_system/vessel_system/start_usv_tmux.sh
```

When the container is no longer running, revoke the X11 permission:

```bash
xhost -si:localuser:root
```

## Gazebo selection

Do not install the generic `ros-humble-ros-gz`,
`ros-humble-ros-gz-sim`, or `ros-humble-ros-gz-bridge` packages in this image.
On ROS 2 Humble those packages target Gazebo Fortress and conflict with the
Harmonic bridge installed by `ros-humble-ros-gzharmonic`.
