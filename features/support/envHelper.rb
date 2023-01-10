require "capybara/cucumber"
require "selenium/webdriver"
require 'yaml'
require 'json'
require 'os'

module EnvHelper

  def setCapybaraHost()
    Capybara.app_host= $platformConfig['datasite'][ENV['datacenter']][ENV['env']]['vdrURL']
  end

  def setLambdaCredentials()
    ENV['username'] = 'username_here'
    ENV['accessToken'] = 'accesskey_here'
  end

  def setLambdaURL()
    lambdaURL = 'https://username:accesskey@hub.lambdatest.com/wd/hub'
    return lambdaURL
  end

  def setLambdaBuildName()
    if ENV['jobExecutionPlatform'] == 'jenkins'
      $lambda_build = ENV['datacenter'].upcase + "-" + ENV['env'].upcase + "-" + ENV['tag'].capitalize + "-" + ENV['sys'].capitalize + "-" + ENV['browser'].capitalize + "-" + ENV['app_lang'].upcase + ": " + ENV['BUILD_NUMBER']
    else
      $lambda_build = nil
    end
  end

  def setLambdaJobname(scenario)
    $jobName = ENV['datacenter'].upcase + "-" + ENV['env'].capitalize + "-" + ENV['app_lang'].upcase + ' => ' + "#{scenario.feature.name} - #{scenario.name}"
  end

  def getScenarioTags(scenario)
    tags = Array.new
    for tag in scenario.feature.tags do
      tags.push(tag.name)
    end
    for tag in scenario.tags do
      tags.push(tag.name)
    end
    tags.push(ENV['env'])
    return tags.uniq
  end

  def setConfigFilePath()
    $filePath = ""
    usrCur = Dir.pwd

    if OS.windows?
      $filePath = usrCur.gsub('/','\\')+"\\features\\support\\"
    elsif OS.linux? || OS.mac?
      $filePath = usrCur.gsub('/','/')+"/features/support/"
    end

    $objRepo = YAML.load_file("#{$filePath}objectRepository.yaml")
    $platformConfig = JSON.parse(File.read("#{$filePath}platformConfigs.json"))

  end

  def runScenarios(scenario, block)
    scenario_times = {}
    start = Time.now
    block.call
    sessionid = ::Capybara.current_session.driver.browser.session_id
    ::Capybara.current_session.driver.quit

    sc = if scenario.respond_to?(:scenario_outline)
           scenario.scenario_outline
         else
           scenario
         end
    t = scenario_times["#{sc.feature.file}::#{scenario.name}"] = Time.now - start

    jobname = "#{scenario.feature.name} - #{scenario.name}"
    puts"---------------------------------------------------------"
    puts "Starting Test :: #{jobname}"
    puts start
    puts "Finishing TEST :: #{jobname}"
    puts Time.now
    puts "### TEST  COMPLETED IN #{t}s"
    puts "---------------------------------------------------------"
    puts "Lambda Test Link: https://automation.lambdatest.com/logs/?sessionID=#{sessionid}"
  end

  def setLambdaJobStatus(scenario)
    if scenario.failed?
      ::Capybara.current_session.driver.execute_script('lambda-status=failed')
    elsif scenario.passed?
      ::Capybara.current_session.driver.execute_script('lambda-status=passed')
    end
  end

  def skipMessage(scenario)
    puts("The Scenario " + "\"" + scenario.feature.name.to_s + "\"" + " is SKIPPED.")
  end

end

World(EnvHelper)
