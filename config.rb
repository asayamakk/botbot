class Config
  class << self
    attr_reader :issue_emoji, :done_emoji, :slack_team, :github_owner, :github_repo
    def setup(file = 'config.json')
      json = File.read(file)
      config = JSON.parse(json)
      @issue_emoji = config["issue_emoji"]
      @done_emoji = config["done_emoji"]
      @slack_team = config["slack_team"]
      @github_owner = config["github_owner"]
      @github_repo = config["github_repo"]
    end
  end
end
