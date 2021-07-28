module Selenium
  module WebDriver
    module Remote
      module Http
        class MerrillClient < Default
          private
          # Skips this step and the remaining steps in the scenario
          def skip_this_scenario(message = "Scenario skipped")
            raise Cucumber::Core::Test::Result::Skipped, message
          end
          def request(*)
            retries = 0
            super
          rescue Errno::ETIMEDOUT
            raise if retries >= MAX_RETRIES
            retries += 1
            puts "Trying second time" + retries.to_s
            sleep 2
            retry
          rescue Selenium::WebDriver::Error::ServerError,Net::ReadTimeout,RestClient::ServerBrokeConnection
            puts "Got 500 internal server error or Net read time out error or server broke connection skipping the test or Timed out connecting to server"
            skip_this_scenario
          end
          # Skips this step and the remaining steps in the scenario
        end # MerrillClient
      end # Http
    end # Remote
  end # WebDriver
end # Selenium
