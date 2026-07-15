# RMF Demos

The Open Robotics Middleware Framework ([Open-RMF](https://github.com/open-rmf/rmf)) enables interoperability among heterogeneous robot fleets, managing shared resources (space, lifts, doors), robot traffic and task allocation. This repository contains demonstrations of these capabilities and serves as a starting point for working and integrating with Open-RMF.

## System Requirements

* [Docker Engine](https://docs.docker.com/engine/install/) and an X server on your graphical desktop session (Gazebo and RViz open windows on your display)
* A GPU is recommended; the launch command uses the AMD GPU passthrough flags (`/dev/kfd`, `/dev/dri`)
* ~10 GB disk (~6 GB simulation image, ~1.5 GB rmf-web images, plus model cache), ~8 GB RAM

## Quick Start

```bash
./demo.sh run-server       # rmf-web API server on localhost:8000
./demo.sh run-dashboard    # web dashboard on localhost:3000
./demo.sh check            # verify both containers are running
./demo.sh download office  # pre-download the scene's Gazebo models (once per scene)
./demo.sh run office       # launch the simulation (Ctrl-C to stop)
```

Then dispatch tasks from the [rmf-web](https://github.com/open-rmf/rmf-web) dashboard at [localhost:3000](http://localhost:3000) (*Create Task → Patrol*), or from the CLI:

```bash
./demo.sh task patrol -p pantry lounge coe -n 3
```

When you are done:

```bash
./demo.sh stop
```

Every command accepts `--help`; `./demo.sh run --help` lists the available scenes, `./demo.sh task --help` lists the available tasks (`--use_sim_time` is appended to tasks automatically).

The simulation connects to the API server via `server_uri:="ws://localhost:8000/_internal"`, so the fleet adapters stream live robot and task states to the dashboard. The API server's Swagger UI is at `localhost:8000/docs`.

## Demo Worlds

* [Hotel World](#hotel-world)
* [Office World](#office-world)
* [Airport Terminal World](#airport-terminal-world)
* [Clinic World](#clinic-world)
* [Campus World](#campus-world)

Each world keeps its own model-cache volume (`rmf_gz_models_<scene>`), so its assets download once with `./demo.sh download <scene>` and are reused afterwards.

---

### Hotel World

This hotel world consists of a lobby and 2 guest levels. The hotel has two lifts, multiple doors and 3 robot fleets (4 robots).
This demonstrates an integration of multiple fleets of robots with varying capabilities working together in a multi-level building.

![](../media/hotel_world.png)

#### Demo Scenario

To launch the world and the schedule visualizer,

```bash
./demo.sh download hotel
./demo.sh run hotel
```

Here, we will showcase 2 types of Tasks: **Patrol** and **Clean**, you can dispatch them via CLI as follows:
```bash
./demo.sh task patrol -p restaurant L3_master_suite -n 1
./demo.sh task clean -cs clean_lobby
```

Robots running Clean and Patrol tasks:

![](../media/hotel_scenarios.gif)

---

### Office World
An indoor office environment for robots to navigate around. It includes a beverage dispensing station, controllable doors and laneways which are integrated into RMF.

```bash
./demo.sh download office
./demo.sh run office   # office is the default: ./demo.sh run
```

Now we will showcase 2 types of Tasks: **Delivery** and **Patrol**

![](../media/delivery_request.gif?raw=true)

You can request the robot to deliver a can of coke from `pantry` to `hardware_2` through the following:
```bash
./demo.sh task delivery -p pantry -ph coke_dispenser -d hardware_2 -dh coke_ingestor
```

You can also request the robot to move back and forth between `coe` and `lounge` through the following:
```bash
./demo.sh task patrol -p coe lounge -n 3
```

![](../media/loop_request.gif)

---

### Airport Terminal World

This demo world shows robot interaction on a much larger map, with a lot more lanes, destinations, robots and possible interactions between robots from different fleets, robots and infrastructure, as well as robots and users. In the illustrations below, from top to bottom we have how the world looks like in `traffic_editor`, the schedule visualizer in `rviz`, and the full simulation in `gazebo`,

![](../media/airport_terminal_traffic_editor_screenshot.png)
![](../media/airport_terminal_demo_screenshot.png)

#### Demo Scenario
To launch the world:

```bash
./demo.sh download airport_terminal
./demo.sh run airport_terminal
```

You can submit `patrol`, `delivery` or `clean` tasks via CLI:
```bash
./demo.sh task patrol -p s07 n12 -n 3
./demo.sh task delivery -p mopcart_pickup -ph mopcart_dispenser -d spill -dh mopcart_collector
./demo.sh task clean -cs zone_3
```

---

### Clinic World

This is a clinic world with two levels and two lifts for the robots. Two different robot fleets with different roles navigate across two levels by lifts. In the illustrations below, we have the view of level 1 in `traffic_editor` (top left), the schedule visualizer in `rviz` (right), and the full simulation in `gazebo` (bottom left).

![](../media/clinic.png)

#### Demo Scenario
To launch the world and the schedule visualizer,

```bash
./demo.sh download clinic
./demo.sh run clinic
```

You can submit tasks via CLI:
```bash
./demo.sh task patrol -p L1_left_nurse_center L2_right_nurse_center -n 5
./demo.sh task patrol -p L2_north_counter L1_right_nurse_center -n 5
```

Robots taking lift:

![](../media/robot_taking_lift.gif)


Multi-fleet demo:

![](../media/clinic.gif)

---
### Campus World

This is a larger scale "Campus" World. In this world, there are multiple delivery robots that operate. The world is designed and traffic lanes are annotated at the planet scale, using GPS WGS84 coordinates. Each robot is also streaming its location in WGS84 coordinates, which are processed by its fleet adapter. This demo intends to show the potential of Open-RMF on a large scale map.

![](../media/campus.gif)

#### Demo Scenario
To launch the world and the schedule visualizer,

```bash
./demo.sh download campus
./demo.sh run campus

./demo.sh task patrol -p room_5 campus_4 -n 10
./demo.sh task patrol -p campus_5 room_3 -n 10
./demo.sh task patrol -p room_2 dead_end -n 10
```

## Advanced Scenarios

Advanced scenarios (traffic-light robot demos, lift watchdog, emergency alarm, RobotManager bridge) are covered in [README.upstream.md](README.upstream.md). For ad-hoc ROS 2 commands, open a sourced shell inside the running simulation container:

```bash
./demo.sh shell
```

## Troubleshooting

- **Dashboard at `localhost:3000` loads but stays empty.** The simulation started before the API server was ready. Wait a couple of seconds, then restart the simulation (`./demo.sh run <scene>`); its logs should show `Successfully connected to ws://localhost:8000/_internal`.
- **`localhost:8000` shows a 404.** That is normal: the API server has no root page. Use `localhost:8000/docs` for its Swagger UI.
- **Gazebo takes minutes to open.** Fuel models are being downloaded at launch - run `./demo.sh download <scene>` first.
- **`glx: failed to create dri3 screen` / sluggish rendering.** The GPU is not reaching the container. Verify `/dev/dri` exists on the host. On a machine with no usable GPU, add `-e LIBGL_ALWAYS_SOFTWARE=1` to the `docker run` command in `demo.sh`'s `cmd_run` to accept CPU rendering.

---

For more information or the original running instructions (source build, ROS 2 launch files), see [README.upstream.md](README.upstream.md).
