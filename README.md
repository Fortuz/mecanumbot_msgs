# mecanumbot_msgs

ROS 2 interface package for the mecanumbot. It contains only message and service
definitions — no nodes. Every other package in the workspace
(`mecanumbot`, `mecanumbot_behaviours`, `mecanumbot_camera`, `mecanumbot_remote`,
`mecanumbot_sensorprocess_smart`) depends on this package for its custom types.

Build type is `ament_cmake` with `rosidl_generate_interfaces`; generated types are
available in C++ (`mecanumbot_msgs/msg/...hpp`) and Python
(`from mecanumbot_msgs.msg import ...`).

The package deliberately stays small: **11 messages and 2 services**. Retiring
`mecanumbot_gui` removed the last consumers of the controller-event and
action-mapping types, so 5 messages and 12 services were deleted with it
(`ButtonEvent`, `JoystickEvent`, `ControllerStatus`, `ActionTuple`,
`ActionDescriptor`, and the `Get`/`Save`/`Delete` mapping, action and
recording-scheme services).

Its replacement, `mecanumbot_joy`, is configured by YAML rather than by ROS
services, and uses only standard interfaces at runtime — `std_srvs/Trigger` for
reload and e-stop clearing, `rcl_interfaces/SetParameters` for profile
switching, and `std_msgs/String`/`Bool` for status. Prefer that pattern before
adding a type here: a custom interface should carry robot data, not
configuration.

## Build

```bash
cd ~/Documents/mecanumbot_ws
colcon build --packages-select mecanumbot_msgs
source install/setup.bash
```

Dependencies: `std_msgs`, `geometry_msgs`, `builtin_interfaces`, `action_msgs`.

New `.msg`/`.srv` files must be added to the `msg_files` / `srv_files` lists in
`CMakeLists.txt` — a file dropped into `msg/` or `srv/` is **not** generated
automatically.

## Messages

### Hardware and low-level control

| Message | Function | Used by |
| --- | --- | --- |
| `OpenCRState.msg` | Full telemetry frame from the OpenCR board: goal/measured wheel velocities, positions, currents and accelerations, per-wheel error states, neck and grabber goal positions, DMS distance measure, battery voltage, and 9-axis IMU data (angular velocity, linear acceleration, magnetometer, orientation quaternion). | `mecanumbot_core` |
| `AccessMotorCmd.msg` | Goal positions for the accessory servos: neck (`n_pos`), left grabber (`gl_pos`), right grabber (`gr_pos`). | `mecanumbot_core`, `mecanumbot_monitor`, `mecanumbot_teleop`, behaviour packages |

### Audio

| Message | Function | Used by |
| --- | --- | --- |
| `AudioInfo.msg` | Stream description: channel count, sample rate, sample subtype and stream UUID. | `mecanumbot_audio` |
| `AudioData.msg` | A block of `float32` audio samples. | `mecanumbot_audio` |

### People detection

| Message | Function | Used by |
| --- | --- | --- |
| `PersonKeypoints.msg` | The 17 COCO pose keypoints (nose, eyes, ears, shoulders, elbows, wrists, hips, knees, ankles) as `geometry_msgs/Pose`. | `mecanumbot_sensorprocess_smart` |
| `CamPersonDetection.msg` | One detected person: keypoints plus right/left angular bounds (`bound_angle_min`/`bound_angle_max`) and a type string. | `mecanumbot_sensorprocess_smart` |
| `CamPersonDetectionArray.msg` | Stamped array of `CamPersonDetection`, published on `cam_people_detections`. | `mecanumbot_sensorprocess_smart` |

### Simulation and evaluation

| Message | Function | Used by |
| --- | --- | --- |
| `SimActor.msg` | A simulated actor: id, name, kind, whether it is the tracked subject, LiDAR visibility, pose and twist. | `mecanumbot_core` |
| `SimActorArray.msg` | Stamped array of `SimActor` for a named scenario. | `mecanumbot_core` |
| `SimBehaviorEvaluation.msg` | Per-scenario behaviour verdict: command availability, motion and target validity, unsafe-motion / proximity / wall-proximity / wrong-target / stale-detection flags, commanded speed, subject and nearest-actor/wall/human distances, plus `status` and `reason`. | `mecanumbot_core` |
| `SimDetectionEvaluation.msg` | Per-scenario detection verdict: detection availability, subject tracking state, false-wall and wrong-human lock flags, raw detection count, nearest actor id/name/kind/distance, subject error, nearest wall distance and `status`. | `mecanumbot_core` |

## Services

### LED control

Served by `mecanumbot_led`, which forwards the values over serial to the Arduino
Nano LED controller. Mode and color value tables are documented in that package's
README.

| Service | Request | Response |
| --- | --- | --- |
| `SetLedStatus.srv` | `mode`/`color` per panel (`fl`, `fr`, `br`, `bl`). | `success`, `message` |
| `GetLedStatus.srv` | empty | Current `mode`/`color` per panel. |

## Repository layout

| File or folder | Function |
| --- | --- |
| `msg/` | Message definitions. |
| `srv/` | Service definitions. |
| `CMakeLists.txt` | Lists the `.msg`/`.srv` files passed to `rosidl_generate_interfaces`. |
| `package.xml` | Package manifest; member of the `rosidl_interface_packages` group. |
| `LICENSE` | Apache-2.0. |
