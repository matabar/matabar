# Include the root configuration. This directory is not itself a stack.
include "root" {
  path = find_in_parent_folders("root.hcl")
}

exclude {
  if      = true
  actions = ["plan", "apply"]
}
