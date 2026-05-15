# ControllerStatus.msg
# Published on /controller/connection_status by controller_node.
# The node publishes this on every /joy callback, so reception of this
# message implicitly means the controller is connected.
# Disconnection is detected by docker_node's _controller_watchdog when
# this topic goes silent.

string  controller_type  # detected layout, e.g. "Controller 360" or "Generic Controller"
