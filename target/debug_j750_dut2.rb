# Production mode will require that there are no modified files in the workspace
# and any other conditions that you add to your application.
# Normally production targets define the target and then debug targets
# are setup to load the production target before switching Origen to debug
# mode as shown below.
load "#{Origen.root}/target/production_j750_dut2.rb"

Origen.mode = :debug
