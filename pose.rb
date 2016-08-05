require 'erb'
require 'highline/import'

class Point
  attr_reader :energy, :time
  def initialize(energy, time)
    @energy = energy
    @time = time
  end
  def power
    @energy / @time
  end
end

class Pose
  attr_accessor :min_power, :max_power    # System Parameters
  attr_accessor :energy_exp, :delay_exp   # Metric Parameters
  attr_accessor :name, :code  # Code Parameters (name and a Point)

  def opt_intercept(point, power)
    # p_theta = point.power
    # t_theta = point.time
    (point.energy**@energy_exp * point.time**@delay_exp / power**@energy_exp) \
      ** (1/ (@energy_exp + @delay_exp))
  end

  def cont_intercept(point, power)
    # p_theta = point.power
    # t_theta = point.time
    point.time * (power / point.power) ** (@energy_exp / (@energy_exp + @delay_exp))
  end

  # Pmax / Optimisation Limit Interept
  def A
    a_time = opt_intercept(C(), @max_power)
    Point.new(a_time * @max_power, a_time)
  end

  # Pmax / Optimisation Bound Intercept
  def B
    b_time = opt_intercept(@code, @max_power)
    Point.new(b_time * @max_power, b_time)
  end

  # Pmin / Contribution Bound Intercept
  def C
    c_time = cont_intercept(@code, @min_power)
    Point.new(c_time * @min_power, c_time)
  end

  # Pmin at code time
  def D
    Point.new(@code.time * min_power, @code.time)
  end

  # Pmin / Optimisation Bound Intercept
  def E
    e_time = opt_intercept(@code, @min_power)
    Point.new(e_time * @min_power, e_time)
  end

  def metric_value(point)
    point.energy**@energy_exp * point.time**@delay_exp
  end
end

def build_model
  model = Pose.new
  choose do |menu|
    menu.default = 'ED^2P'
    menu.prompt = "Please select a metric: |#{menu.default}| "
    menu.choices('Energy', 'EDP', 'ED^2P', 'ED^3P', 'Custom') do |metric|
      case metric
      when 'Energy'
        model.energy_exp, model.delay_exp = 1.0, 0.0
      when 'EDP'
        model.energy_exp, model.delay_exp = 1.0, 1.0
      when 'ED^2P'
        model.energy_exp, model.delay_exp = 1.0, 2.0
      when 'ED^3P'
        model.energy_exp, model.delay_exp = 1.0, 3.0
      when 'Custom'
        model.energy_exp = ask("Energy Exponent (m): ", Float)
        model.delay_exp = ask("Delay Exponent (n): ", Float)
      end
    end
  end
  model.min_power = ask('System Min Power (W): ', Float) { |q| q.above = 0 }
  model.max_power = ask('System Max Power (W): ', Float) { |q| q.above = model.min_power }
  model.name = ask('Code Name: ')
  code_energy = ask('Code Energy (J): ', Float) { |q| q.above = 0 }
  code_time = ask('Code Time (S): ', Float) do |q|
    q.below = code_energy / model.min_power
    q.above = code_energy / model.max_power
  end   
  model.code = Point.new(code_energy, code_time)
  model
end

# Let's Do this!
say 'POSE Model creation'
model = build_model
erbfile = ask('Report Template: ') { |t| t.default = 'templates/latex_report.erb' }
template = ERB.new(File.new(erbfile).read, nil, '-')
outfile = ask ('Output Filename: ') { |o| o.default = "#{model.name}.tex" }
report = template.result(binding)
File.write(outfile, report)
