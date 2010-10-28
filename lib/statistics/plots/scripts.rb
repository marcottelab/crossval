# Plot hypergeometric k=200 against pearson k=200 (naivebayes)
h = {}
h['hypergeometric'] = Experiment.find 638
h['pearson'] = Experiment.find 641
t = Statistics::Plots::ExperimentsScatterPlot.new h
t.plot :roc_area

h = {}
h['hypergeometric200'] = Experiment.find 638
h['hypergeometric10'] = Experiment.find 718
t = Statistics::Plots::ExperimentsScatterPlot.new h
t.plot :roc_area