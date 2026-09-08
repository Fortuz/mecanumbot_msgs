# The robot found the thing it was sent for and cannot have it.
#
# Published when a seeking episode ends in an object the robot located but could
# not reach or grip -- a mug on a table, a box behind a barrier, something the
# pincer cannot close on. It is the record of an experimental event, not a log
# line: what was sought, where it turned out to be, why it could not be had, and
# whether anybody was actually told.

std_msgs/Header header

# What was being sought, as free text rather than a class label -- the query the
# operator gave, which is what a person reading the record wants to see.
string object_class

# Where the robot last placed it, in the map frame.
geometry_msgs/Point object_position

# Height above the floor, in metres. The number the 2D map cannot supply and the
# point cloud can -- it is what distinguishes "on the floor behind something"
# from "on a table", and a floor-level pincer can only do anything about the
# first.
float32 object_height

# Why it could not be had:
#   too_high     above what the grabbers can close on
#   too_low      below the shafts (in a recess, under something)
#   no_route     nav2 could not get the robot to it
#   grip_failed  the robot reached it and the grabbers caught nothing
#   lost         it was seen and then could not be found again
string reason

# --- who was told -------------------------------------------------------------
# Whether a person was found and shown the object. False means the robot ended
# the episode with nobody to tell, which is a different outcome and has to be
# distinguishable in the record.
bool person_informed

# Where that person stood, in the map frame. Meaningless when person_informed
# is false.
geometry_msgs/Point person_position

# How many times the robot alternated its orientation between the person and the
# object -- the showing gesture. Zero when nobody was told.
uint8 gaze_alternations
