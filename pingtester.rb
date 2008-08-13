#!/usr/bin/env ruby
require "xmlrpc/client"

begin
sourceURI = "http://www.noexpectations.com.au/articles/pingback-tester"
targetURI = "http://www.noexpectations.com.au/articles/no-expectations-revisited"
server = XMLRPC::Client.new( "www.noexpectations.com.au", "/xmlrpc/api")
result = server.call("pingback.ping", sourceURI, targetURI );

puts result
rescue XMLRPC::FaultException => e
    puts "Error:"
    puts e.faultCode
    puts e.faultString
end