# RMF Demos

![](https://github.com/open-rmf/rmf_demos/workflows/build/badge.svg)
![](https://github.com/open-rmf/rmf_demos/workflows/style/badge.svg)

The Open Robotics Middleware Framework (Open-RMF) enables interoperability among heterogeneous robot fleets while managing robot traffic that share resources such as space, building infrastructure systems (lifts, doors, etc) and other automation systems within the same facility. Open-RMF also handles task allocation and conflict resolution among its participants (de-conflicting traffic lanes and other resources). These capabilities are provided by various libraries in [Open-RMF](https://github.com/open-rmf/rmf).
For more details about Open RMF, refer to the comprehensive documentation provided [here](https://osrf.github.io/ros2multirobotbook/intro.html).

This repository contains demonstrations of the above mentioned capabilities of RMF. It serves as a starting point for working and integrating with Open-RMF.

This fork adds [`demo.sh`](demo.sh), a wrapper around the official Open-RMF Docker images (`ghcr.io/open-rmf/rmf/rmf_demos`, ROS 2 Kilted + Gazebo Ionic), so every demo below runs without building anything locally. The original source-build instructions are kept in [README.upstream.md](README.upstream.md).

[![Robotics Middleware Framework](../media/thumbnail.png?raw=true)](https://vimeo.com/405803151)

#### (Click to watch video)

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

Then dispatch tasks from the dashboard at [localhost:3000](http://localhost:3000) (*Create Task → Patrol*), or from the CLI:

```bash
./demo.sh task patrol -p pantry lounge coe -n 3
```

When you are done:

```bash
./demo.sh stop
```

Every command accepts `--help`; `./demo.sh run --help` lists the available scenes, `./demo.sh task --help` lists the available tasks (`--use_sim_time` is appended to tasks automatically).

## FAQ
Answers to frequently asked questions can be found [here](docs/faq.md).

## Roadmap

A near-term roadmap of the Open-RMF project can be found in the user manual [here](https://osrf.github.io/ros2multirobotbook/roadmap.html).

## RMF-Web

Full web application of Open-RMF: [rmf-web](https://github.com/open-rmf/rmf-web).

`./demo.sh run-server` starts the backend API server (`ghcr.io/open-rmf/rmf-web/api-server`) with host network access, accessible at `localhost:8000` (Swagger UI at `localhost:8000/docs`). `./demo.sh run-dashboard` starts the frontend dashboard (`ghcr.io/open-rmf/rmf-web/demo-dashboard`), accessible at `localhost:3000`.

`./demo.sh run` launches the simulation with `server_uri:="ws://localhost:8000/_internal"`, so the fleet adapters update the api-server with the latest task and robot states. You can then monitor on-going states and initiate RMF tasks from the web dashboard.

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

Robots running Clean and Loop Task:

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

## Task Dispatching in Open-RMF
![](../media/RMF_Bidding.png)

In Open-RMF version `21.04` and above, tasks are awarded to robot fleets based on the outcome of a bidding process that is orchestrated by a Dispatcher node, `rmf_dispatcher_node`. When the Dispatcher receives a new task request from a UI, it sends out a `rmf_task_msgs/BidNotice` message to all the fleet adapters. If a fleet adapter is able to process that request, it submits a `rmf_task_msgs/BidProposal` message back to the Dispatcher with a cost to accommodate the task. An instance of `rmf_task::agv::TaskPlanner` is used by the fleet adapters to determine how best to accommodate the new request. The Dispatcher compares all the `BidProposals` received and then submits a `rmf_task_msgs/DispatchRequest` message with the fleet name of the robot that the bid is awarded to. There are a couple different ways the Dispatcher evaluates the proposals such as fastest to finish, lowest cost, etc which can be configured.

Battery recharging is tightly integrated with the new task planner. `ChargeBattery` tasks are optimally injected into a robot's schedule when the robot has insufficient charge to fulfill a series of tasks. Currently we assume each robot in the map has a dedicated charging location as annotated with the `is_charger` option in the traffic editor map.

## Other Tools and Features

The traffic-light robot demos, lift watchdog, emergency alarm, RobotManager bridge and other advanced scenarios require extra launch files or host-side ROS 2 tooling that the Docker wrapper does not cover; see [README.upstream.md](README.upstream.md) for those, or open a shell inside the running simulation container:

```bash
docker exec -it rmf_demos bash -c 'source /opt/ros/kilted/setup.bash && source /rmf_demos_ws/install/setup.bash && exec bash'
```

## Troubleshooting

- **Dashboard at `localhost:3000` loads but stays empty.** The simulation started before the API server was ready. Wait a couple of seconds, then restart the simulation (`./demo.sh run <scene>`); its logs should show `Successfully connected to ws://localhost:8000/_internal`.
- **`localhost:8000` shows a 404.** That is normal: the API server has no root page. Use `localhost:8000/docs` for its Swagger UI.
- **Gazebo takes minutes to open.** Fuel models are being downloaded at launch - run `./demo.sh download <scene>` first.
- **`glx: failed to create dri3 screen` / sluggish rendering.** The GPU is not reaching the container. Verify `/dev/dri` exists on the host. On a machine with no usable GPU, add `-e LIBGL_ALWAYS_SOFTWARE=1` to the `docker run` command in `demo.sh`'s `cmd_run` to accept CPU rendering.
