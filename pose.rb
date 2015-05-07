require 'erb'
require 'highline/import'

Metric = Struct.new(:energy_exp, :delay_exp)
Envelope = Struct.new(:max_power, :min_power)
Code = Struct.new(:name, :energy, :time, :power)

module Metrics
  Energy = Metric.new(1.0, 0.0) # Simple energy
  EDP = Metric.new(1.0, 1.0)    # Energy Delay Product
  ED2P = Metric.new(1.0, 2.0)   # Energy Delay Squared Product
  ED3P = Metric.new(1.0, 3.0)   # Energy Delay Cubed Product
end

def metric_parameters
  choose do |menu|
    menu.prompt = 'Please select a metric: '
    menu.choice('Energy') { Metrics::Energy }
    menu.choice('Energy Delay Product') { Metrics::EDP }
    menu.choice('Energy Delay Squared Product') { Metrics::ED2P }
    menu.choice('Energy Delay Cubed Product') { Metrics::ED3P }
    menu.choice('Custom') do
      custom = Metric.new
      custom.energy_exp = ask("Energy Exponent (m): ", Float)
      custom.delay_exp = ask("Delay Exponent (n): ", Float)
      custom
    end
  end
end

def envelope_parameters
  envelope = Envelope.new
  envelope.min_power = ask('System Min Power (W): ', Float) { |q| q.above = 0 }
  envelope.max_power = ask('System Max Power (W): ', Float) { |q| q.above = envelope.min_power }
  envelope
end

def code_parameters
  code = Code.new
  code.name = ask('Code Name: ')
  code.energy = ask('Code Energy (J): ', Float) { |q| q.above = 0 }
  code.time = ask('Code Time (S): ', Float) { |q| q.above = 0 }
  code.power = code.energy / code.time
  code
end

# TODO - add bounds checking for parameters
# TODO - support arguments or queries (make it query for missing arguments)
# TODO - support 2 out of 3 runtime / power / energy

say 'POSE Model creation'
metric = metric_parameters()
envelope = envelope_parameters()
code = code_parameters()
if code.power > envelope.max_power or code.power < envelope.min_power
  raise 'Invalid Model Parameters'
end

erbfile = ask('Report Template: ') { |t| t.default = 'templates/report.erb' }
template = ERB.new(File.new(erbfile).read, nil, '-')
outfile = ask ('Output Filename: ') { |o| o.default = 'report.tex' }
report = template.result(binding)
File.write(outfile, report)
