@login @smoke
Feature: Login negative functionality
	As a user I want to test negative login

	@unsuccessfulLogin1
	Scenario: Test 25 - Unsuccessful Login
		Given I open the app
		When I enter username test@datasite.com and password something
		Then I should be on the login page