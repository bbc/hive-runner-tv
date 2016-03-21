require 'hive/device'

module Hive
  class Device
    # The TV worker
    class Tv < Device
      def initialize(config)
        @identity = config['id']

        # TODO This can be removed when DeviceDB is no longer being used
        config['queues'] = [ "#{config['brand'].downcase.gsub(/\s/, '_')}-#{config['model'].downcase.gsub(/\s/, '_')}-test" ]
        super
      end
    end
  end
end
