require 'hive/worker'
require 'hive/messages/tv_job'

module Hive
  class Worker
    # The TV worker
    class Tv < Worker
      # Prepare the TV
      def pre_script(job, job_paths, script)
        url = job.application_url
        @log.info("Application url: #{url}")
        Hive.devicedb('Device').poll(@options['id'], 'busy')

        params = ""

        # 'cross_network_restriction' means that the device requires Talkshow
        # on the same network as the application.
        # For the moment, assume networks are '10.10.*.*' and'*.bbc.co.uk'
        # TODO Make this more general
        if @options['features'].include?('cross_network_restriction') and /bbc.co.uk/.match url
          ts_address = Hive.config.network.remote_talkshow_address
          ts_port = Hive.config.network.remote_talkshow_port_offset + @options['id']
          @log.info("Using remote talkshow on port #{ts_port}")
          script.set_env 'TALKSHOW_REMOTE_URL', "http://#{ts_address}:#{ts_port}"
          # Not actually required but talkshow fails without it set
          script.set_env 'TALKSHOW_PORT', ts_port
        else
          ts_port = @ts_port = Hive::data_store.port.assign(Process.pid)
          @log.info("Using talkshow on port #{ts_port}")
          # TODO Move this more centrally
          ip = Socket.ip_address_list.detect { |intf| intf.ipv4_private? }
          ts_address = ip.ip_address
          script.set_env 'TALKSHOW_PORT', ts_port
        end
        @log.info("Talkshow server address is: #{ts_address}")

        if job.application_url_parameters.present?
          params = "?#{job.application_url_parameters}&talkshowurl=#{ts_address}:#{ts_port}"
        else
          params = "?talkshowurl=#{ts_address}:#{ts_port}"
        end
        params += "&devicedbid=#{@options['id']}"
        url += params

        @log.info("Redirecting TV to: #{url}")

        retry_count = 0
        max_count = 15
        @log.info("Waiting for device to get into app")
        Hive.devicedb('Device').action(@options['id'], 'redirect', url, 3)
        @log.info("Application name: #{Hive.devicedb('Device').get_application(@options['id'])}")
        sleep 5
        while Hive.devicedb('Device').get_application(@options['id']) == Hive.config.network.tv.titantv_name
          sleep 1
          if retry_count >= max_count
            @log.info("  (Resend redirect)")
            Hive.devicedb('Device').action(@options['id'], 'redirect', url, 3)
            sleep 5
            retry_count = 0
          end
          retry_count += 1
          @log.info("  .#{retry_count}")
        end

        return nil
      end

      def job_message_klass
        Hive::Messages::TvJob
      end

      def post_script(job, job_paths, script)
        Hive::data_store.port.release(@ts_port) if @ts_port

        max_count = 15
        retry_count = max_count
        resend_count = 0
        Hive.devicedb('Device').action(@options['id'], 'redirect', Hive.config.network.tv.titantv_url)
        sleep 5
        @log.info("Waiting for holding app to launch")
        # TODO from here
        while Hive.devicedb('Device').get_application(@options['id']) != Hive.config.network.tv.titantv_name
          if retry_count >= max_count
            resend_count = resend_count + 1
            # TODO Configuration option
            if resend_count > 30
              raise FailedRedirect
            end
            @log.info("Redirecting to the holding app")
            Hive.devicedb('Device').action(@options['id'], 'redirect', Hive.config.network.tv.titantv_url)
            retry_count = 0
            sleep 5
          end
          retry_count += 1
          @log.info("  .#{retry_count}")
          sleep 1
        end
        Hive.devicedb('Device').poll(@options['id'], 'idle')
      end

      def device_status
        details = Hive.devicedb('Device').find(@options['id'])
        @log.debug("Device details: #{details.inspect}")
        details['status']
      end

      def checkout_code(repository, checkout_directory)
        Hive.devicedb('Device').action(@options['id'], 'message', "Checking out code from #{repository}")
        super
      end
    end
  end
end
