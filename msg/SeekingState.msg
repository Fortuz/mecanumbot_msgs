# The state of the modelled SEEKING circuit, published for the record.
#
# Panksepp's SEEKING system is appetitive and anticipatory: it is sustained by
# expectancy rather than by receipt, it outlasts the stimulus that engaged it,
# and it switches off on consummation. This message is that state as the seek
# behaviour tree computes it, so a trial can be replayed against what the robot
# was doing and why.
#
# It is deliberately NOT a reward-prediction error. Panksepp rejects the
# reduction of SEEKING to RPE explicitly; see mecanumbot_seek/README.md.

std_msgs/Header header

# What is being sought, as free text rather than a class label -- it is the
# query the server's open-vocabulary detector is given, so "the red mug on the
# desk" is a better value here than "mug". Empty during undirected seeking, when
# the circuit is engaged by the opportunity to explore rather than by any
# particular object.
string object_class

# Short-term activation: how hard the robot is seeking right now. [0..1]
float32 arousal

# Medium-term expectancy -- the "mood" layer. Falls slowly under repeated
# non-reward, which is what turns a directed approach into a widening search
# and eventually ends the episode. [0..1]
float32 expectancy

# --- what is driving it -------------------------------------------------------
bool object_in_sight

# Seconds since the last incentive event (a sighting, or arriving somewhere the
# object was expected). The circuit decays from here.
float32 seconds_since_cue

# How wide the search pattern is currently working, in metres. Grows as
# expectancy falls: less certainty about where it is, more ground covered.
float32 search_radius

# undirected | directed | approach | consummatory | extinguished
string phase
