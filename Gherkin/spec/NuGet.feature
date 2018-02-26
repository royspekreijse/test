Feature: should have latest NuGet present

Scenario: Install NuGet
    Given a windows based machine with minimum OS level 2012R2
    Given a working Internet connection
    Given PowerShell 5.0 or higher present
    Given PowerShell session is running elevated
    Given latest NuGet package provider is not installed
    Then install latest NuGet package provider
