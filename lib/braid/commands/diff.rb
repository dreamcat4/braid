module Braid
  module Commands
    class Diff < Command
      def run(path)
        mirror = config.get!(path)
        if mirror.type == "git-clone"
          unless system("cd #{mirror.path} && git diff")
            msg "Error diffing \"#{path}\" in \"#{mirror.path}\""
            exit 1
          end
        else
          setup_remote(mirror)

          diff = mirror.diff
          puts diff unless diff.empty?
        end
      end
    end
  end
end
