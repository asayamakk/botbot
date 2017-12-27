class ApplicationLogger < Logger
  class << self

    def setup
      @instance = self.new('bot.log')
    end
  end
end
