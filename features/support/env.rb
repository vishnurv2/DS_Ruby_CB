require "capybara/cucumber"
require "selenium/webdriver"
require 'yaml'
require 'json'
require 'os'
require 'report_builder'
require_relative '../support/envHelper'

include EnvHelper

ENV['env'] ||= "dev"
ENV['run'] ||= 'lambda'
ENV['browser'] ||= 'chrome'
ENV['sys'] ||= 'windows'
ENV['app_lang'] ||= 'en'
ENV['datacenter'] ||= 'USA'
ENV['jobExecutionPlatform'] ||= 'nonJenkins'
ENV['JENKINS_BUILD_NUMBER'] ||= ' '
ENV['tag'] ||= 'Local Terminal'
ENV['extDebug'] ||= 'true'
ENV['spo'] ||= 'false'
ENV['proxy'] ||= 'false'
ENV['headless'] ||= 'false'
ENV['foundry'] ||= 'g'

ENV['env'] = ENV['env'].downcase
EnvHelper.setConfigFilePath
EnvHelper.setCapybaraHost
EnvHelper.setLambdaBuildName

CONFIG = YAML.load_file("#{$filePath}objectRepository.yaml")

@lang = ENV['app_lang']

if ENV['run'] == 'lambda'
  EnvHelper.setLambdaCredentials()
  lambdaURL = EnvHelper.setLambdaURL()

  After do |scenario|
    EnvHelper.setLambdaJobStatus(scenario)
  end

  AfterStep do
    puts Time.new
  end

  Before do | scenario |
    EnvHelper.setLambdaJobname(scenario)
    tags = scenario.tags
    custom_client = Selenium::WebDriver::Remote::Http::MerrillClient.new
    custom_client.read_timeout = 200

    os_version = $platformConfig[ENV['sys']]['osVersion']
    browser_version = $platformConfig[ENV['sys']]['browserVersion']

    @scenarioName = scenario.name
    @scenarioLocation = scenario.location.to_s.split(":")[0]
    $featureFlag = nil
    tags.each do |tag|
      if tag.name.start_with? "@language_"
        index = tag.name.index "_"
        @lang = tag.name[index + 1 .. tag.name.size - 1]
      elsif tag.name.start_with? "@featureFlag_"
        $featureFlag = tag.name.split("_")[1]
      end
    end

    ENV['tunnelName'] = nil if ENV['tunnelName']=='null' || ENV['tunnelName'] == 'nil'

    if ENV['browser'] == 'chrome'
      options = Selenium::WebDriver::Chrome::Options.new
      options.add_preference('intl.accept_languages', @lang)
      capabilities = Selenium::WebDriver::Remote::Capabilities.chrome(
          platformName: os_version,
          browserVersion: browser_version, #$platformConfig[ENV['sys']][browsers][chrome]
          screenResolution: $platformConfig[ENV['sys']]['resolution'],
          "selenium_version" => $platformConfig['webdriver_version'],
          "lambda:userFiles" => [
              "uploadToSingleFolder.pdf",
              "file1.pdf",
              "FailedFileToUpload.dtd",
              "replacesearchdoc.docx",
              "contentMgrUploadFile.pdf",
              "ZipMaintainStructure.zip",
              "ZipUpload.zip"
          ],
          commandTimeout: $platformConfig['commandTimeout'],
          idleTimeout: $platformConfig['idleTimeout'],
          build: $lambda_build,
          name: $jobName
      )
    end
    Capybara.register_driver :selenium do |app|
      Capybara::Selenium::Driver.new(app,
                                     browser: :remote,
                                     url: lambdaURL,
                                     desired_capabilities: capabilities,
                                     options: options,
                                     http_client: custom_client
      )

    end

    Capybara.default_max_wait_time = 10
    Capybara.current_driver = :selenium
    window = Capybara.current_session.driver.browser.manage.window
    window.maximize()
  end

elsif ENV['run'] == 'local'
  capabilities = {
      commandTimeout: $platformConfig['commandTimeout']
  }
  if ENV['browser'] == 'chrome'
    Capybara.default_driver = :selenium
    browserName = :chrome
    options = Selenium::WebDriver::Chrome::Options.new
    options.add_preference('intl.accept_languages', @lang)
    if ENV['headless'] == 'true'
      options.add_argument('--headless')
    end
  end
  Capybara.register_driver :selenium do |app|
    Capybara::Selenium::Driver.new(app,
                                   browser: browserName,
                                   desired_capabilities: capabilities,
                                   options: options
    )
  end

  Capybara.default_max_wait_time = 10
  window = Capybara.current_session.driver.browser.manage.window
  window.maximize()
end