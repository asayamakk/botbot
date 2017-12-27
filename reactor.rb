class Reactor
  @logger = Logger.new(STDOUT, 2)

  # @param reaction_data Hash
  # Reference: https://api.slack.com/events/reaction_added
  #
  # {
  #   "type" => "reaction_added",
  #   "user" => <user_id>,
  #   "item" => {
  #     "type" => <messageとかfileとか...>,
  #     "channel" => <channel_name messageのとき>
  #     "ts" => <timestamp messageのとき>
  #   },
  #   "event_ts" => <reactionがついたts>
  # }
  def self.react_to_message(reaction_data)
    if reaction_data.dig("item", "type") != 'message' || reaction_data.dig("reaction") != Config.issue_emoji
      @logger.debug("Item is not message or Reaction is not matched skipping... reaction: #{reaction_data.dig("reaction")}")
      return nil
    end

    channel, ts = reaction_data["item"]["channel"], reaction_data["item"]["ts"].to_s
    user_id = reaction_data["user"]
    message = SlackHandler.get_message(channel, ts)
    if message.dig("messages")&.[](0)&.[]("reactions")&.any? {|item| item["name"] == Config.done_emoji}
      @logger.debug("Already marked with #{Config.done_emoji}, skipping... channel: #{channel}, ts: #{ts}")
      return nil
    end

    title = message["messages"]&.[](0)&.[]("text") || "メッセージの取得に失敗しました... :bow:"
    reply_url = "https://gmo-media.slack.com/archives/#{channel}/p#{ts[0..-7]}.#{ts[-6..-1]}"
    options = {body: reply_url + "\r\n\r\n>" + title}
    response = GithubHandler.create_issue(Config.github_owner, Config.github_repo, filter_title(title), options: options)
    issue_url = response["html_url"]
    @logger.info("Issue is created, url: issue_url")
    bot_reply = "Hello #{SlackHandler.search_user(user_id) || "unknown"}-san,\r\nThank you for the report.\r\n#{issue_url}"
    message_option = { as_user: true }
    SlackHandler.post_message(channel, bot_reply, options: message_option)
    SlackHandler.add_reaction(Config.done_emoji, channel, ts)
  end

  def self.filter_title(text)
    regex_at_user = /<@[a-zA-Z0-9]*>/
    regex_subteam = /<!subteam^[a-zA-Z0-9]*|@[a-zA-Z0-9]*>/
    text.gsub(regex_at_user, "")
        .gsub(regex_subteam, "")
        .strip
        .[](0, 256)
  end
end
