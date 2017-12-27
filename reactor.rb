class Reactor
  @logger = Logger.new('bot.log')

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
    if reaction_data.dig("item", "type") != 'message' || reaction_data.dig("reaction") != 'book'
      @logger.debug("Reaction is not matched skipping... reaction: #{reaction_data.dig("reaction")}")
      return nil
    end

    channel, ts = reaction_data["item"]["channel"], reaction_data["item"]["ts"].to_s
    user_id = reaction_data["user"]
    message = SlackHandler.get_message(channel, ts)
    if message.dig("messages")&.[](0)&.[]("reactions")&.any? {|item| item["name"] == 'heavy_check_mark'}
      @logger.debug("Already marked with heavy_check_mark, skipping... channel: #{channel}, ts: #{ts}")
      return nil
    end

    title = message["messages"]&.[](0)&.[]("text") || "メッセージの取得に失敗しました... :bow:"
    reply_url = "https://gmo-media.slack.com/archives/#{channel}/p#{ts[0..-7]}.#{ts[-6..-1]}"
    options = {body: reply_url + "\r\n\r\n>" + title}
    response = GithubHandler.create_issue("gmo-media", "DBA.Misc", filter_title(title), options: options)
    issue_url = response["html_url"]
    bot_reply = "Hello #{SlackHandler.search_user(user_id) || "unknown"}-san,\r\nThank you for the report.\r\n#{issue_url}"
    SlackHandler.post_message(channel, bot_reply)
    SlackHandler.add_reaction("heavy_check_mark", channel, ts)
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
