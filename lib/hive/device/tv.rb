require 'hive/device'

module Hive
  class Device
    # The TV worker
    class Tv < Device
      def initialize(config)
        @identity = config['id']
        super
      end
    end
  end
end
