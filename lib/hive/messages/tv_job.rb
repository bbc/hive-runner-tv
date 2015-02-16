# encoding: UTF-8

require 'hive/messages'

module Hive
  module Messages
    class TvJob <  Hive::Messages::Job
# TODO Fix this validation
#      validates :application_url, :application_url_parameters, presence: true

      def application_url
        self.target.symbolize_keys[:application_url]
      end

      def application_url_parameters
        self.target.symbolize_keys[:application_url_parameters]
      end
    end
  end
end
