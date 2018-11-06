Feature: Command Line Processing
  As an payment originator I want to be able to use
  Zold as a command line tool

  Scenario: Help can be printed
    When I run bin/zold-stress with "-h"
    Then Exit code is zero
    And Stdout contains "--help"

  Scenario: Version can be printed
    When I run bin/zold-stress with "--version"
    Then Exit code is zero

  Scenario: Test round can be executed
    When I run bin/zold-stress with "--public-key=id_rsa.pub --private-key=id_rsa --wallet=0123456701234567"
    Then Exit code is zero
