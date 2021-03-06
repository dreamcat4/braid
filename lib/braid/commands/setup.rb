module Braid
  module Commands
    class Setup < Command
      def run(path = nil)
        path ? setup_one(path) : setup_all
      end

      protected
        def setup_all
          msg "Setting up all mirrors."
          config.mirrors.each do |path|
            setup_one(path)
          end
        end

        def setup_one(path)
          mirror = config.get!(path)

          if mirror.type == "git-clone"
            return
          end

          if git.remote_url(mirror.remote)
            msg "Setup: Mirror '#{mirror.path}' already has a remote. Reusing it." if verbose?
            return
          end

          msg "Setup: Creating remote for '#{mirror.path}'."
          unless mirror.type == "svn"
            url = use_local_cache? ? git_cache.path(mirror.url) : mirror.url
            git.remote_add(mirror.remote, url, mirror.branch)
          else
            git_svn.init(mirror.remote, mirror.url)
          end
        end
    end
  end
end
