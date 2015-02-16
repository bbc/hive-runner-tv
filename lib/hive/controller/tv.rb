require 'hive/controller'
require 'hive/worker/tv'

module Hive
  class Controller
    # The TV controller
    class Tv < Controller
      def detect
        Hive.devicedb.find_disconnected_by_type('tv')['devices'].collect do |device|
          Hive.logger.debug("Found TV #{device}")
          device['queues'] = device['device_queues'].collect do |queue_details|
            queue_details['name']
          end
          Hive.devicedb.action(device['id'], 'message', 'Found by hive. Waiting for work.')
          Object.const_get(@device_class).new(@config.merge(device))
        end
      end
    end
  end
end
