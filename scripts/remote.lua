local power = require("scripts/power")
local plugin = require("scripts/plugins")
local remote_gauges = {}
local remote_histograms = {}
local remote_counters = {}
local interface = {}

interface = {
  power_rescan_networks = function()
    power.rescan_worlds()
  end,
  get_plugin_events = function()
    return plugin.get_events()
  end,
  -- Return a new counter every time
  make_counter = function(name, desc, labels)
    local counter = prometheus.counter(name, desc, labels)
    remote_counters[name] = counter
    return remote_counters[name]
  end,
  -- Re-use counter, if not existing create a new one
  get_counter = function(name, desc, labels)
    if not remote_counters[name] then
      return interface.make_counter(name, desc, labels)
    end
    return remote_counters[name]
  end,
  counter_set = function(name, value, labels)
    local counter = interface.get_counter(name)
    counter:set(value, labels)
  end,
  -- Return a new gauge every time
  make_gauge = function(name, desc, labels)
    local gauge = prometheus.gauge(name, desc, labels)
    remote_gauges[name] = gauge
    return remote_gauges[name]
  end,
  -- Re-use gauge, if not existing create a new one
  get_gauge = function(name, desc, labels)
    if not remote_gauges[name] then
      return interface.make_gauge(name, desc, labels)
    end
    return remote_gauges[name]
  end,
  gauge_set = function(name, value, labels)
    local gauge = interface.get_gauge(name)
    gauge:set(value, labels)
  end,
  gauge_inc = function(name, value, labels)
    local gauge = interface.get_gauge(name)
    gauge:inc(value, labels)
  end,
  gauge_dec = function(name, value, labels)
    local gauge = interface.get_gauge(name)
    gauge:dec(value, labels)
  end,
  -- Return a new histogram every time
  make_histogram = function(name, desc, labels)
    local histogram = prometheus.histogram(name, desc, labels)
    remote_histograms[name] = histogram
    return remote_histograms[name]
  end,
  -- Re-use histogram, if not existing create a new one
  get_histogram = function(name, desc, labels)
    if not remote_histograms[name] then
      return interface.make_histogram(name, desc, labels)
    end
    return remote_histograms[name]
  end,
  histogram_observe = function(name, value, labels)
    local histogram = interface.get_histogram(name)
    histogram:histogram_observe(value, labels)
  end
}

return {
  add_remote_interface = function()
    if not remote.interfaces["graftorio"] then
      remote.add_interface("graftorio", interface)
    end
  end
}