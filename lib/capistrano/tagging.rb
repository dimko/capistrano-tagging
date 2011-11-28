unless Capistrano::Configuration.respond_to?(:instance)
  abort "capistrano/tagging requires Capistrano 2"
end

require 'capistrano'

Capistrano::Configuration.instance(:must_exist).load do

  after  "deploy:restart", "tagging:deploy"
  before "deploy:cleanup", "tagging:cleanup"

  namespace :tagging do

    def tag(options = {})
      return fetch(:tag_format, ":rails_env_:release").gsub(/:([a-z_]+[^_:])/i) do |match|
        method = $1.to_sym
        match  = options[method] || fetch(method, false) || (send(method) rescue '')
      end
    end

    desc "Place release tag into Git and push it to server."
    task :deploy do
      user = `git config --get user.name`
      email = `git config --get user.email`

      puts `git tag #{tag(:release => release_name)} #{revision} -m "Deployed by #{user} <#{email}>"`
      puts `git push --tags`
    end

    desc "Remove deleted release tag from Git and push it to server."
    task :cleanup do
      count = fetch(:keep_releases, 5).to_i
      if count >= releases.length
        logger.important "no old release tags to clean up"
      else
        logger.info "keeping #{count} of #{releases.length} release tags"

        tags = (releases - releases.last(count)).map { |release| tag(:release => release) }

        tags.each do |tag|
          `git tag -d #{tag}`
          `git push origin :refs/tags/#{tag}`
        end
      end
    end

  end

end
