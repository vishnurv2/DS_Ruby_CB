require 'yaml'
require 'os'
config = YAML.load_file("#{$filePath}objectRepository.yaml")
$cfg=config

Then(/^I should be on the login page$/) do
  begin
    expect(page).to have_content('LOG IN', wait:120)
    expect(page).to have_xpath(config['registration']['signOn'].sub("TEXT", 'Sign On'), wait:10)
    url = URI.parse(current_url)
    expect(url).not_to eq("#{$platformConfig['datasite'][ENV['datacenter']][ENV['env']]['vdrURL']}/jv/login/")
  rescue Selenium::WebDriver::Error::StaleElementReferenceError => exception
    expect(page).to have_content('LOG IN', wait:120)
  end
end

When(/^I enter username ([^"]*) and password ([^"]*)$/) do |loginEmailAddress, loginPassword|
  find(:xpath, "//input[@id='username']", wait:30).native.send_keys(loginEmailAddress)
  find(:xpath, "//input[@id='password']").native.send_keys(loginPassword)
  sleep 5
  find(:xpath, "//a[text()='LOG IN']").click
end

When(/^I just enter username ([^"]*) and password ([^"]*)$/) do |loginEmailAddress, loginPassword|
  find(:xpath, "//input[@id='username']", wait:30).native.send_keys(loginEmailAddress)
  find(:xpath, "//input[@id='password']").native.send_keys(loginPassword)
  sleep 5
end

Given(/^I open the app$/) do
  visit '/'
  sleep(1)
  step 'I should be on the login page'
end
