module Backup
  module Syncer
    module Cloud
      class CliS3Syncer < S3
        def perform!
          log!(:started)
          paths_to_push.each do |local_path|
            local_path_last = local_path.split('/').last
            run("aws s3 sync --storage-class=STANDARD_IA #{exclude_option} #{local_path} s3://#{bucket}/#{path}#{local_path_last}")
          end
          log!(:finished)
        end

        def exclude_option
          excludes.map { |pattern| " --exclude=\"#{pattern}\"" }.join
        end

        def paths_to_push
          directories.map { |dir| File.expand_path(dir) }
        end

        def check_configuration
          required =
            if use_iam_profile
              %w[bucket]
            else
              %w[access_key_id secret_access_key bucket]
            end
          raise Error, <<-EOS if required.map { |name| send(name) }.any?(&:nil?)
            Configuration Error
            #{required.map { |name| "##{name}" }.join(", ")} are all required
          EOS
        end
      end
    end
  end
end

module Backup
  class Pipeline
    def no_stderr?
      @stderr.empty? || @stderr.to_s.strip.chomp == 'Warning: Using a password on the command line interface can be insecure.'
    end

    def stderr_messages
      @stderr_messages ||= no_stderr? ? false : <<-EOS.gsub(/^ +/, "  ")
        Pipeline STDERR Messages:
        (Note: may be interleaved if multiple commands returned error messages)
        #{@stderr}
      EOS
    end
  end
end