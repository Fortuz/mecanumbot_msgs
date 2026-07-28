# mecanumbot_msgs

ROS 2 interface package for the mecanumbot. It contains only message and service
definitions — no nodes. Every other package in the workspace
(`mecanumbot`, `mecanumbot_behaviours`, `mecanumbot_camera`, `mecanumbot_remote`,
`mecanumbot_sensorprocess_smart`) depends on this package for its custom types.

Build type is `ament_cmake` with `rosidl_generate_interfaces`; generated types are
available in C++ (`mecanumbot_msgs/msg/...hpp`) and Python
(`from mecanumbot_msgs.msg import ...`).

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
| `SensorState.msg` | Bumper, cliff, sonar, illumination, LED, button, torque, wheel encoder and battery state, plus constants for bumper/cliff/button masks, motor error codes and torque flags. Legacy type — present in `msg/` but **not** listed in `CMakeLists.txt`, so it is currently not generated. | — |

### Controller input and action mapping

These types back the controller/teleop stack. The controller node publishes the
event messages instead of the older `std_msgs/String` + JSON encoding.

| Message | Function |
| --- | --- |
| `ButtonEvent.msg` | Published on `/controller/button_events`: event kind (`PRESSED`/`HOLD`/`RELEASED`), button name, button index in the `joy.buttons` array (`-1` for D-Pad), and timestamp in ROS clock seconds. |
| `JoystickEvent.msg` | Published on `/controller/joystick_events`: stick or trigger name, `x`/`y` axis values (`-1.0…1.0`; triggers `0.0…1.0` with `y` always `0.0`), and timestamp. |
| `ControllerStatus.msg` | Published on `/controller/connection_status` on every `/joy` callback — receiving it implies the controller is connected. Carries the detected layout string (e.g. `"Controller 360"`). Disconnection is detected by the watchdog when the topic goes silent. |
| `ActionTuple.msg` | One publish step inside an action: topic or service name, JSON-encoded payload, message type, joystick scale/offset factors, and `publish_type` (`"topic"` or `"service"`). |
| `ActionDescriptor.msg` | A complete named action: name, `action_type` (`"button_once"`, `"button_hold"`, `"joystick"`), and the ordered `ActionTuple[]` to publish. |

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

### Stored actions

Actions live in the robot's local database, scoped per `user_name`.

| Service | Function |
| --- | --- |
| `GetRobotActions.srv` | Return all actions for a user as parallel arrays of names, types and JSON blobs. |
| `SaveRobotAction.srv` | Persist a single `ActionDescriptor` (with `overwrite` flag). |
| `DeleteRobotAction.srv` | Delete a named action. |
| `GetActionUsages.srv` | List the mappings that reference a given action — used before deleting. |

### Controller mappings

| Service | Function |
| --- | --- |
| `GetMappingNames.srv` | Names only of the mappings stored for a user (lightweight — no button/joystick data). |
| `GetMappingDetails.srv` | Full button/joystick assignments for one mapping, JSON-encoded. Called when the user opens a robot-side mapping for editing. |
| `SaveMapping.srv` | Persist a named mapping — button names, action names and trigger modes, joystick names and action names, plus the `ActionDescriptor[]` it references. Fails on name conflict unless `overwrite` is set. |
| `DeleteRobotMapping.srv` | Delete a named mapping. |
| `ApplyMapping.srv` | Activate a mapping. With `from_robot_db = true` the robot loads it by name from its own DB; with `false` the host supplies the full mapping and actions in-memory. Responds with the loaded button and joystick counts. |
| `GetMappings.srv` | Older variant of `GetMappingNames`. Present in `srv/` but **not** listed in `CMakeLists.txt`, so it is currently not generated. |

### Recording schemes

A recording scheme is a named list of topics to record for a user.

| Service | Function |
| --- | --- |
| `GetRecordingSchemes.srv` | Return all schemes as parallel arrays of names and JSON topic lists. |
| `SaveRecordingScheme.srv` | Persist a scheme from a name and topic list (with `overwrite` flag). |
| `DeleteRecordingScheme.srv` | Delete a named scheme. |

All of the database-backed services follow the same convention: a `user_name` in
the request, and `bool success` + `string message` in the response, where
`message` carries the error description on failure and is empty on success.

## Repository layout

| File or folder | Function |
| --- | --- |
| `msg/` | Message definitions. |
| `srv/` | Service definitions. |
| `CMakeLists.txt` | Lists the `.msg`/`.srv` files passed to `rosidl_generate_interfaces`. |
| `package.xml` | Package manifest; member of the `rosidl_interface_packages` group. |
| `LICENSE` | Apache-2.0. |
