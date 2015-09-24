require 'hive/controller'
require 'hive/worker/tv'

module Hive
  class Controller
    # The TV controller
    class Tv < Controller
      def detect
        hive_details = Hive.devicedb('Hive').find(Hive.id)

        if hive_details.key?('devices')
          hive_details['devices'].select { |d| d['device_type'] == 'tv' }.collect do |device|
            Hive.logger.debug("Found TV #{device}")
            device['queues'] = device['device_queues'].collect do |queue_details|
              queue_details['name']
            end
            self.create_device(device)
          end
        else
          raise DeviceDetectionFailed
        end
      end
    end
  end
end
