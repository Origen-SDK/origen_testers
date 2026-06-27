# This code is used to extend Origen Core's pin class with additional functionality

require 'origen/pins/pin'

module Origen
  module Pins
    class Pin
      # Returns the channel number for the pin on a given tester site (default = 0), based on a given tester channel
      # map (default_channelmap).  Optionally user can specify site or channelmap.
      def channel(options = {})
        options = {
          chanmapname: $tester.default_channelmap,  # Default is to use default_channelmap
          site:        0 # Default is to use site 0.
        }.merge(options)
        unless $tester.channelmap[options[:chanmapname]]
          fail 'You must first import the tester channel map (e.g. $tester.channelmap = "probe_x32") before calling pin.channel'
        end

        channelinfo = Struct.new(:channel, :chanmapname, :site)
        channelinfo.new($tester.get_tester_channel(options[:chanmapname], name, options[:site]), options[:chanmapname], options[:site])
      end

      # Returns the instrument type for the pin on a given tester site (default = 0), based on a given tester channel
      # map (default_channelmap) and a given tester configuration (default_testerconfig).
      # Optionally user can specify site, channelmap, or testerconfig.
      def instrument_type(options = {})
        options = {
          chanmapname:      $tester.default_channelmap,  # Default is to use default_channelmap
          site:             0, # Default is to use site 0.
          testerconfigname: $tester.default_testerconfig  # Default is to use default_testerconfig
        }.merge(options)

        unless $tester.channelmap[options[:chanmapname]]
          fail 'You must first import the tester channel map (e.g. $tester.channelmap = "probe_x32") before calling pin.channel'
        end
        unless $tester.testerconfig[options[:testerconfigname]]
          fail 'You must first import the tester configuration (e.g. $tester.testerconfig = "UflexConfigA") before calling pin.instrument_type'
        end

        instrumentinfo = Struct.new(:instrument, :chanmapname, :site, :testerconfigname)
        instrumentinfo.new($tester.get_tester_instrument(options[:testerconfigname], $tester.get_tester_channel(options[:chanmapname], name, options[:site]).split('.')[0].to_i), options[:chanmapname], options[:site], options[:testerconfigname])
      end

      # Returns ATE Hardware information for the pin (channel # and instrument type) on a given tester site
      # (default = 0), based on a given tester channelmap (default_channelmap) and a given tester
      # configuration (default_testerconfig).  # Optionally user can specify site, channelmap, or testerconfig.
      def ate_hardware(options = {})
        options = {
          chanmapname:      $tester.default_channelmap,  # Default is to use default_channelmap
          site:             0, # Default is to use site 0.
          testerconfigname: $tester.default_testerconfig  # Default is to use default_testerconfig
        }.merge(options)

        unless $tester.channelmap[options[:chanmapname]]
          fail 'You must first import the tester channel map (e.g. $tester.channelmap = "probe_x32") before calling pin.channel'
        end
        unless $tester.testerconfig[options[:testerconfigname]]
          fail 'You must first import the tester configuration (e.g. $tester.testerconfig = "UflexConfigA") before calling pin.instrument_type'
        end

        if Origen.top_level.power_pin_groups.keys.include?(name)  # Power Pin Groups do not need :ppmu, but need :supply
          instrumentinfo = Struct.new(:channel, :instrument, :chanmapname, :site, :testerconfigname, :supply)
          @channel = $tester.get_tester_channel(options[:chanmapname], name, options[:site])
          @instrument = $tester.get_tester_instrument(options[:testerconfigname], $tester.get_tester_channel(options[:chanmapname], name, options[:site]).split('.')[0].to_i) + $tester.is_vhdvs_hc(options[:chanmapname], name, options[:site]).to_s + $tester.is_hexvs_plus(options[:testerconfigname], @channel.split('.')[0].to_i).to_s + $tester.is_vhdvs_plus(options[:testerconfigname], @channel.split('.')[0].to_i).to_s + $tester.merged_channels(options[:chanmapname], name, options[:site]).to_s
          @supply = $tester.ate_hardware(@instrument).supply
          instrumentinfo.new(@channel, @instrument, options[:chanmapname], options[:site], options[:testerconfigname], @supply)
        else
          if $tester.get_tester_channel(options[:chanmapname], name, options[:site]).split('.')[0].to_i == 24
            instrumentinfo = Struct.new(:channel, :instrument, :chanmapname, :site, :testerconfigname)
            instrumentinfo.new($tester.get_tester_channel(options[:chanmapname], name, options[:site]), $tester.get_tester_instrument(options[:testerconfigname], $tester.get_tester_channel(options[:chanmapname], name, options[:site]).split('.')[0].to_i), options[:chanmapname], options[:site], options[:testerconfigname])
          else
            instrumentinfo = Struct.new(:channel, :instrument, :chanmapname, :site, :testerconfigname, :ppmu)
            instrumentinfo.new($tester.get_tester_channel(options[:chanmapname], name, options[:site]), $tester.get_tester_instrument(options[:testerconfigname], $tester.get_tester_channel(options[:chanmapname], name, options[:site]).split('.')[0].to_i), options[:chanmapname], options[:site], options[:testerconfigname], $tester.ate_hardware($tester.get_tester_instrument(options[:testerconfigname], $tester.get_tester_channel(options[:chanmapname], name, options[:site]).split('.')[0].to_i)).ppmu)
          end
        end
      end
    end
  end
end
