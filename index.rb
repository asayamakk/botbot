require 'faraday'
require 'json'
require 'slack'
require 'logger'
require_relative 'reactor.rb'
require_relative 'slack_handler.rb'
require_relative 'github_handler.rb'

SlackHandler.setup
GithubHandler.setup
logger = Logger.new('bot.log')
client = Slack.realtime

client.on :hello do
  logger.info("Booting application")
end

client.on :reaction_added do |data|
  logger.debug("Received reaction")
  Reactor.react_to_message(data)
end

client.start
