# mecanumbot_msgs

ROS 2 interface package for the mecanumbot. It contains only message and service
definitions — no nodes. Every other package in the workspace
(`mecanumbot`, `mecanumbot_behaviours`, `mecanumbot_camera`, `mecanumbot_remote`,
`mecanumbot_sensorprocess_smart`) depends on this package for its custom types.

Build type is `ament_cmake` with `rosidl_generate_interfaces`; generated types are
available in C++ (`mecanumbot_msgs/msg/...hpp`) and Python
(`from mecanumbot_msgs.msg import ...`).

The package deliberately stays small: **14 messages and 2 services**. Retiring
`mecanumbot_gui` removed the last consumers of the controller-event and
action-mapping types, so 5 messages and 12 services were deleted with it
(`ButtonEvent`, `JoystickEvent`, `ControllerStatus`, `ActionTuple`,
`ActionDescriptor`, and the `Get`/`Save`/`Delete` mapping, action and
recording-scheme services).

The three most recent additions -- `MapCloudAgreement`, `SeekingState` and
`SeekAlert` -- are the Deep3R seeking system's; the object hypotheses that system
passes around are `vision_msgs/Detection3DArray` rather than a type here, which
is the rule below being applied.

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
| `CamPersonDetection.msg` | One detected person: keypoints plus right/left angular bounds (`bound_angle_min`/`bound_angle_max`) and a type string. `mecanumbot_onboard_cam_detect_people` sets `type` to `full_body` or `close_range` — the latter meaning the person is near enough that the shin-height camera framed their legs only, so the upper-body keypoints are outside the image rather than merely undetected. `mecanumbot_cam_detect_people` leaves it empty. | `mecanumbot_sensorprocess_smart` |
| `CamPersonDetectionArray.msg` | Stamped array of `CamPersonDetection`, published on `cam_people_detections`. | `mecanumbot_sensorprocess_smart` |

### The Deep3R seeking system

All three carry data no standard type covers. The seek tree's *object*
hypotheses do not appear here on purpose: a labelled pose with a confidence is
exactly `vision_msgs/Detection3DArray`, and this package is kept for the things a
standard message cannot say.

| Message | Function | Used by |
| --- | --- | --- |
| `MapCloudAgreement.msg` | The server's verdict on comparing the robot's 2D occupancy grid against the Deep3R point cloud: how much of each source the other accounts for, how many cells they disagree about, and — per uncertain region — its map-frame centre, score, **kind** (`cloud_only` / `map_only` / `unobserved` / `disagreement`), **height** and radius. The kind and the height are what make it actionable: a `cloud_only` region 0.10 m tall is a step the lidar plane passed over and becomes a nav2 keepout, one 0.75 m tall is a table the robot drives under. Everything positional is in the robot's own `map` frame, because the server owns the alignment and the robot never reasons in a frame that drifts under it. | `mecanumbot_custom_nav2` |
| `SeekingState.msg` | The modelled SEEKING circuit as the seek tree computes it: short-term `arousal`, medium-term `expectancy`, whether the object is in sight, seconds since the last incentive event, the current search radius and the phase (`undirected` / `directed` / `approach` / `consummatory` / `extinguished`). Published every tick so a trial can be replayed against what the robot was doing and why. | `mecanumbot_seek` |
| `SeekAlert.msg` | The robot found the thing it was sent for and cannot have it: what it was, where, **how high**, why (`too_high` / `too_low` / `no_route` / `grip_failed` / `lost`), whether a person was found and shown it, where they stood, and how many times the showing gesture completed. One per episode that ends that way, **including the ones with nobody to tell** — that is an outcome, not a reason to publish nothing. The height is the field the 2D map cannot supply and is what separates "on a table" from "behind something". | `mecanumbot_seek` |

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
