Feature: Command Line Processing
  As an payment originator I want to be able to use
  Zold as a command line tool

  Scenario: Help can be printed
    When I run bin/zold-stress with "-h"
    Then Exit code is zero
    And Stdout contains "--help"
