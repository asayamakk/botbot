class GithubHandler
  class << self
    attr_reader :token
    def setup(token: nil)
      @token ||= ENV["GITHUB_API_TOKEN"]
      raise(RuntimeError, "You must either set GITHUB_API_TOKEN or pass github token as an argument") if @token.nil?
      @client = Faraday.new(url: 'https://api.github.com/')
      @token
    end

    def get_api(endpoint, parameter: {})
    end

    def post_api(endpoint, parameter: {})
      @client.post do |req|
        req.url endpoint
        req.headers['Content-Type'] = 'application/json'
        req.headers['Authorization'] = "token #{@token}"
        req.body = parameter.to_json
      end
    end

    def create_issue(owner, repo, title, options: {})
      response = post_api("/repos/#{owner}/#{repo}/issues", parameter: {title: title}.merge(options))
      JSON.parse(response.body)
    end
  end

end
