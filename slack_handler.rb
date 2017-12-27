class SlackHandler
  class << self
    def setup(token: nil)
      token ||= ENV["SLACK_API_TOKEN"]
      raise(RuntimeError, "You must either set SLACK_API_TOKEN or pass slack token as an argument") if token.nil?
      Slack.configure do |config|
        config.token = token
      end
      @client = Slack.client
      @realtime = Slack.realtime
    end

    # @param channel String channel_id
    # @param ts String message_timestamp
    # Reference: https://api.slack.com/methods/channels.replies
    def get_message(channel, ts)
      @client.channels_replies(channel: channel, thread_ts: ts)
    end

    def post_message(channel, body, options: {})
      @client.chat_postMessage(channel: channel, text: body, **options)
    end

    def add_reaction(emoji_name, channel, ts)
      @client.reactions_add(name: emoji_name, channel: channel, timestamp: ts)
    end

    def update_user_id_name
      raw = @client.users_list
      @user_id_name = raw["members"].reduce({}) do |accum, member|
        user_id = member["id"]
        user_name = member["name"]
        accum[user_id] = user_name
        accum
      end
    end

    def search_user(id)
      return name if name = @user_id_name&.[](id)
      update_user_id_name
      @user_id_name[id]
    end
  end
end
