require_relative "code_hosting"
require "octokit"

module FastlaneCI
  class GitHubSource < CodeHosting
    class << self
      # Generate a GitHub source based on the user's session
      def source_from_session(session)
        return self.new(email: session["GITHUB_SESSION_EMAIL"],
                        personal_access_token: session["GITHUB_SESSION_API_TOKEN"])
      end
    end

    # The email is actually optional for API access
    # However we ask for the email on login, as we also plan on doing commits for the user
    # and this way we can make sure to configure things properly for git to use the email
    attr_accessor :email

    def initialize(email: nil, personal_access_token: nil)
      self.email = email
      @_client = Octokit::Client.new(access_token: personal_access_token)
    end

    def client
      @_client
    end

    def session_valid?
      client.login.to_s.length > 0
    rescue StandardError
      false
    end

    def username
      client.login
    end

    # TODO: parse those here or in service layer?
    def repos
      client.repos
    end

    # The `target_url`, `description` and `context` parameters are optional
    def set_build_status(repo: nil, sha: nil, state: nil, target_url: nil, description: nil, context: nil)
      available_states = ["error", "failure", "pending", "success"]
      raise "Invalid state '#{state}'" unless available_states.include?(state)

      # TODO: this will use the user's session, so their face probably appears there
      # As Josh already predicted, we're gonna need a fastlane.ci account also
      # that we use for all non-user actions.
      # This includes scheduled things, commit status reporting and probably more in the future

      # Full docs for `create_status` over here https://octokit.github.io/octokit.rb/Octokit/Client/Statuses.html
      client.create_status(repo: repo, sha: sha, state: state, {
        target_url: target_url,
        description: description,
        context: context
      })
    end
  end
end
