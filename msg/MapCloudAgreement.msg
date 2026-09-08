# How the robot's 2D occupancy grid and the server's Deep3R point cloud agree.
#
# Produced on the server, where both the cloud and its logical processing live,
# and consumed on the robot -- by the frontier explorer, which uses it to decide
# whether T1 is finished and where to go and look again.
#
# Everything positional in here is in the robot's own `map` frame. The server
# owns the alignment between CUT3R's world frame and the map frame, so the robot
# never has to reason in a frame that drifts independently of its odometry.

std_msgs/Header header

# --- the two identities, which are not the same thing -------------------------
# These were one field called `map_id`, and the server and the robot meant
# opposite things by it. They invalidate different state on different events, so
# they are now two fields whose names say which is which. See
# RoboCamStreamProcessing/docs/INTEGRATION.md.

# The robot's own SLAM map, as the server echoes it back. A change here means
# these coordinates name a place in a map that no longer exists: slam_toolbox
# has re-rasterised or restarted, and every accumulated region, keepout and
# revisit goal has to be dropped.
string map_id

# The reconstruction session the cloud belongs to. CUT3R anchors its world frame
# on the first frame of a cloud_map_id, so a change here voids everything
# *derived from the cloud's geometry* -- the heights, the region extents -- while
# leaving the robot's map untouched. Empty when the server did not say.
string cloud_map_id

# Points in the cloud at the time of the comparison. A cloud still growing fast
# is a scan that is not finished, whatever the 2D map looks like.
uint32 cloud_points

# --- how much of each source the other one accounts for ----------------------
# Fraction of the 2D map's known-free cells that have cloud points above them.
# The 2D map can be complete while the cloud covers one wall; this is the number
# that says so.
float32 grid_coverage

# Fraction of the cloud that falls inside the 2D map's known region at all.
float32 cloud_coverage

# --- where the two disagree ---------------------------------------------------
# Fraction of the compared cells whose occupancy the two sources agree on.
float32 agreement
uint32 compared_cells

# Cells where the 2D map says free and the cloud has structure, or the reverse.
uint32 conflicting_cells

# --- the places worth going back to -------------------------------------------
# Centres of the regions the comparison is least sure about: a wall the lidar
# drew as a broken line, a cell the two sources disagree about, a patch of floor
# the cloud never covered. These are view-planning targets -- more frames from a
# better viewpoint is the only thing that reliably improves a feed-forward
# reconstruction -- not corrections to either map.
geometry_msgs/Point[] uncertain_points

# Parallel to uncertain_points: 0..1, higher means more worth revisiting.
float32[] uncertain_scores

# Parallel to uncertain_points: what kind of disagreement this is. The robot
# does different things with each, so a bare score is not enough.
#
#   cloud_only   the cloud has structure where the 2D map says free. The lidar
#                is one horizontal plane, so this is the interesting case: a
#                table top, a low step, a cable tray, an overhang. Whether it
#                is an obstacle depends on uncertain_heights below.
#   map_only     the 2D map has an obstacle the cloud never saw. Usually glass,
#                a thin panel, or a surface the camera could not reconstruct --
#                trust the lidar and leave the map alone.
#   unobserved   the cloud never covered this part of the map at all. A place
#                to go and look from, not a disagreement.
#   disagreement the two sources conflict in a way neither of the above covers.
string[] uncertain_kinds

# Parallel to uncertain_points: height above the floor of the structure the
# cloud sees there, in metres; 0 where there is none (map_only, unobserved).
# This is what turns a cloud_only region into a decision -- structure the robot
# would hit is a keepout, structure it drives under is not.
float32[] uncertain_heights

# Parallel to uncertain_points: radius of the region, in metres.
float32[] uncertain_radii
