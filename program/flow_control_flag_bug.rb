# Flow to exercise the Flow Control API
#
# Some of the other flows also cover the flow control API and those tests are used
# to guarantee that the test ID references work when sub-flows are involved.
# This flow provides a full checkout of all flow control methods.
Flow.create interface: 'OrigenTesters::Test::Interface', flow_name: "Flow Control Testing" do
  flow.flow_description = 'Flow to exercise the Flow Control API' if tester.v93k?

  self.resources_filename = 'flow_control'

  log "Mixed-case manual flags"
  test :test1, on_fail: { set_flag: :$My_Mixed_Flag }, continue: true, number: 51420
  test :test2, if_flag: "$My_Mixed_Flag", number: 51430
  unless_flag "$My_Mixed_Flag" do
    test :test3, number: 51440
  end
  
  log "Mixed-case manual flags - induce frozen string error"
  test :test4, on_fail: { set_flag: :$My_Mixed_Flag }, continue: true, number: 51450
  test :test5, if_flag: "$My_Mixed_Flag", number: 51460
  unless_flag "$My_Mixed_Flag" do
    test :test6, number: 51470
  end

end
