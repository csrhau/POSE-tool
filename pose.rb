require 'highline/import'

Parameters = Struct.new(:energy_exp, :delay_exp)


def populate_metric(params)
  choose do |menu|
    menu.prompt = 'Please select a metric: '
    menu.choice('Energy') do
      params.energy_exp = 1.0
      params.delay_exp = 0.0
    end
    menu.choice('Custom') do
      params.energy_exp = ask("Energy Exponent (m): ", Float)
      params.delay_exp = ask("Delay Exponent (n): ", Float)
    end
  end
end


say 'POSE Model creation'
params = Parameters.new
populate_metric(params)
p params

