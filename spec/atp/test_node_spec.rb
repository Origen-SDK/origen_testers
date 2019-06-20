require 'spec_helper'

describe 'Test nodes' do
  include OrigenTesters::ATP::FlowAPI

  before :each do
    self.atp = OrigenTesters::ATP::Program.new.flow(:sort1) 
  end

  def ast
    atp.ast(add_ids: false)
  end

  it "can capture limit information" do
    test :test1, limits: [{ value: 5, rule: :lte}, { value: 1, rule: :gt, units: :mV }]
    test :test2, limits: :none
    test :test3, high: 5
    test :test4, low: 22

    ast.should ==
       s(:flow,
         s(:name, "sort1"),
         s(:test,
           s(:object, "test1"),
           s(:limit, 5, "lte", nil, nil),
           s(:limit, 1, "gt", "mV", nil)),
         s(:test,
           s(:object, "test2"),
           s(:nolimits)),
         s(:test,
           s(:object, "test3"),
           s(:limit, 5, "lte", nil, nil)),
         s(:test,
           s(:object, "test4"),
           s(:limit, 22, "gte", nil, nil)))
  end

  it "can capture target pin information" do
    test :test1, pin: { name: :pinx }
    test :test2, pins: [{ name: :pinx}, { name: :piny}]

    ast.should ==
       s(:flow,
         s(:name, "sort1"),
         s(:test,
           s(:object, "test1"),
           s(:pin, "pinx")),
         s(:test,
           s(:object, "test2"),
           s(:pin, "pinx"),
           s(:pin, "piny")))
  end

  it "can include level information" do
    test :test1, level: { name: :vdd, value: 1.5 }
    test :test2, levels: [{ name: :vdd, value: 1.1}, { name: :vddc, value: 700, units: :mV}]

    ast.should ==
       s(:flow,
         s(:name, "sort1"),
         s(:test,
           s(:object, "test1"),
           s(:level, "vdd", 1.5)),
         s(:test,
           s(:object, "test2"),
           s(:level, "vdd", 1.1),
           s(:level, "vddc", 700, "mV")))
  end

  it "can include arbitrary attributes/meta data" do
    test :test1, meta: { frequency: 25, cz: true }

    ast.should ==
       s(:flow,
         s(:name, "sort1"),
         s(:test,
           s(:object, "test1"),
           s(:meta,
             s(:attribute, "frequency", 25),
             s(:attribute, "cz", true))))
  end

  it "bin nodes can include a description" do
    test :test1, bin: 5, bin_description: "This is bad news"

    ast.should ==
       s(:flow,
         s(:name, "sort1"),
         s(:test,
           s(:object, "test1"),
           s(:on_fail,
             s(:set_result, "fail",
               s(:bin, 5, "This is bad news")))))
  end

  it "can capture a list of patterns" do
    test :test1, pattern: "my_pattern"
    test :test2, patterns: ["my_pat1", { name: "my_pat2", path: "production/flash" }]

    ast.should ==
       s(:flow,
         s(:name, "sort1"),
         s(:test,
           s(:object, "test1"),
           s(:pattern, "my_pattern")),
         s(:test,
           s(:object, "test2"),
           s(:pattern, "my_pat1"),
           s(:pattern, "my_pat2", "production/flash")))
  end

  it "can include sub-tests" do
    test :test1, 
      sub_tests: [
        sub_test(:test1_s1, limits: [{ value: 5, rule: :lte}, { value: 1, rule: :gt, units: :mV }]),
        sub_test(:test1_s2, bin: 10),
    ]

    ast.should ==
       s(:flow,
         s(:name, "sort1"),
         s(:test,
           s(:object, "test1"),
           s(:sub_test,
             s(:object, "test1_s1"),
             s(:limit, 5, "lte", nil, nil),
             s(:limit, 1, "gt", "mV", nil)),
           s(:sub_test,
             s(:object, "test1_s2"),
             s(:on_fail,
               s(:set_result, "fail",
                 s(:bin, 10))))))
  end
end
