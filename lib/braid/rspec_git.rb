module RSpec
  class Git

    attr_reader :name, :path, :url

    def initialize(name, path, url)
      @name = name
      @path = path
      @url = url
    end
    
    def plugins_fetched?
      submodules.all? {|s| File.directory?(s[:path]) }
    end
    
    def update(target)
      check_for_clean_repos "Unable to update"
      
      repos.each do |r|
        if File.exist?(r[:path])
          msg "** Updating #{r[:name]}"
          # target = ENV['REMOTE'] ? "#{ENV['REMOTE']} master" : ""
          unless system("cd #{r[:path]} && git pull --rebase #{target}")
            msg "Error updating #{r[:name]}"
            exit 1
          end
        else
          msg "** Fetching #{r[:name]}"
          system "git clone #{r[:url]} #{r[:path]}"
        end
      end
      msg "*** all repos updated successfully ***"
    end
    
    def status
      repos.each do |r|
        msg "\n** #{r[:name]} status"
        system "cd #{r[:path]} && git status"
      end
    end

    def push
      check_for_clean_repos "Unable to push"

      repos.each do |r|
        msg "** push #{r[:name]}"
        unless system("cd #{r[:path]} && git push && git push --tags")
          msg "Error pushing #{r[:name]}"
          exit 1
        end
      end
      msg "Successfully pushed changes to github"
    end

    def commit
      if ENV['MESSAGE'].nil?
        msg "You must pass a commit message.  Try it again with:\n" +
          "rake git:commit MESSAGE='commit message here'"
        return
      end
      
      repos.each do |r|
        output = `cd #{r[:path]} && git status`
        unless output.include?('On branch master')
          msg "*** #{r[:name]} is not on the master branch.  Skipping"
          next
        end
        msg "** Committing #{r[:name]}"
        system "cd #{r[:path]} && git commit -a -m #{ENV['MESSAGE'].inspect}"
      end
    end

    def hard_reset
      repos.each do |r|
        msg "\n** Resetting #{r[:name]}"
        system "cd #{r[:path]} && git add . && git reset --hard"
      end
      msg
    end

    def add_remotes
      if ENV['REPO_PREFIX'].nil? || ENV['NAME'].nil?
        msg "You must pass a prefix and name.  Try it again with (e.g.):\n" +
          "rake git:add_remotes REPO_PREFIX='git://github.com/dchelimsky' NAME='dc'"
        return
      end

      repos.each do |r|
        system "cd #{r[:path]} && git remote add #{ENV['NAME']} #{r[:url]}"
      end
    end
    
    def tag
      if ENV['TAG'].nil?
        msg "You must pass a tag. Try again like so:\n" +
          "  TAG=1.1.4 rake git:tag"
        return
      end
      repos.each do |r|
        system "cd #{r[:path]} && git tag #{ENV['TAG']}"
      end
    end

    private
    def check_for_clean_repos(message)
      unless all_repos_clean?
        msg "*** #{message} ***"
        status
        exit 1
      end
    end
    
    def all_repos_clean?
      repos.all? do |r|
        !File.exist?(r[:path]) ||
        (output = `cd #{r[:path]} && git status`;
         output.include?('On branch master') &&
         !output.include?('Changes to be committed:') &&
         !output.include?('Changed but not updated:'))
      end
    end
    
    def repos
      # [submodules, superproject].flatten
      [ {:name => @name, :path => @path, :url => @url} ]
    end

    # def superproject
    #   {:name => "rspec-dev", :path => ".",
    #    :url => "#{url_prefix}/rspec-dev.git"}
    # end
    
    # def submodules
    #   [
    #    {:name => "TextMate Bundle", :path => 'RSpec.tmbundle',
    #     :url => "#{url_prefix}/rspec-tmbundle.git" },
    #    {:name => "rspec", :path => 'example_rails_app/vendor/plugins/rspec',
    #     :url => "#{url_prefix}/rspec.git"},
    #    {:name => "rspec-rails", :path => 'example_rails_app/vendor/plugins/rspec-rails',
    #     :url => "#{url_prefix}/rspec-rails.git"}
    #   ]
    # end

    def url_prefix
      if ENV["COMMITTER"]
        "git@github.com:dreamcat4"
      elsif ENV["REPO_PREFIX"]
        ENV["REPO_PREFIX"]
      else
        "git://github.com/dreamcat4"
      end
    end
  end
end
