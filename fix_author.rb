require 'open3'
require 'optparse'

DBUG = true

DefaultWorkDir = "./work".freeze


# String extension method for red terminal output, e.g. error messages.
# Example:
#   `puts "Something broke!".red`
class String
  def red
    "\e[31m#{self}\e[0m"
  end
end


# A databag for a single CLI option.
class CLIOption
  attr_reader :symbol, :param_key, :short_name, :long_name, :description

  private def gen_param_key(symbol)
    symbol.to_s.gsub("_", "-").to_sym
  end

  private def gen_long_name(param_key, has_arg)
    long_name = "--#{param_key}"

    if has_arg
      arg_name = param_key.to_s.gsub("-", "").upcase
      long_name += " #{arg_name}"
    end

    long_name
  end

  def initialize(symbol:, short_name:, has_arg:, description:)
    @symbol      = symbol
    @param_key   = gen_param_key symbol
    @short_name  = "-#{short_name}".freeze
    @long_name   = gen_long_name(@param_key, has_arg).freeze
    @description = description.freeze
  end

  def clone
    CLIOption.new(
      symbol:      @symbol,
      param_key:   @param_key,
      short_name:  @short_name,
      has_arg:     @has_arg,
      description: @description,
    )
  end

  def symbol()      @symbol;      end
  def param_key()   @param_key;   end
  def short_name()  @short_name;  end
  def long_name()   @long_name;   end
  def description() @description; end

  # Create a hash of this option's properties for iteration.
  def all
    props = Hash.new
    props[:symbol]      = @symbol
    props[:param_key]   = @param_key
    props[:short_name]  = @short_name
    props[:long_name]   = @long_name
    props[:description] = @description
    props.freeze
  end

  # A pretty printable string representation
  def to_s
    props = all
    maxlen = props.keys.max { |a, b| a.length <=> b.length }.length
    props.each.each_with_object([]) do |(pkey, pval), lines|
      pkey_pad = "#{pkey}:".ljust(maxlen + 2)
      lines << "#{pkey_pad}#{pval}"
    end.join("\n")
  end
end


# Convenience class and Source of Truth for command line option definitions.
# Helps prevent magic strings.
class AllCLIOptions
  # Proto option definitions are used to generate the option definitions.
  # Why? This approach reduces string repetition.
  @proto_option_defs =
    [
      {symbol:      :old_name,
       short_name:  'm'.freeze,
       has_arg:     true,
       description: 'The old author name.'.freeze},

      {symbol:      :old_email,
       short_name:  'd'.freeze,
       has_arg:     true,
       description: 'The old author email.'.freeze},

      {symbol:      :new_name,
       short_name:  'n'.freeze,
       has_arg:     true,
       description: 'The new author name.'.freeze},

      {symbol:      :new_email,
       short_name:  'e'.freeze,
       has_arg:     true,
       description: 'The new author email.'.freeze},

      {symbol:      :repo_url,
       short_name:  'r'.freeze,
       has_arg:     true,
       description: 'GitHub repo URL.'.freeze},

      {symbol:      :work_dir,
       short_name:  'w'.freeze,
       has_arg:     true,
       description: 'The working directory for the fix. Defaults to CWD.'.freeze},

      {symbol:      :help,
       short_name:  'h'.freeze,
       has_arg:     false,
       description: 'Shows this help text.'.freeze},
    ].freeze

  # Expose the proto option definitions for testing
  def self.proto_option_defs
    @proto_option_defs.clone.freeze
  end

  # Initiolize the option definitions
  @option_defs = @proto_option_defs.each.each_with_object({}) do |opt, defs|
    defs[opt[:symbol]] =
      CLIOption.new(
        symbol:      opt[:symbol],
        short_name:  opt[:short_name],
        has_arg:     opt[:has_arg],
        description: opt[:description],
      )

    puts "#{defs[opt[:symbol]].to_s}" if DBUG; puts if DBUG
  end

  def self.get_def(opt_sym)
    if @option_defs.key? opt_sym
      @option_defs[opt_sym]
    else
      raise "No CLI option definition for key \":#{opt_sym.to_s}\""
    end
  end

  def self.old_name()  get_def :old_name;  end
  def self.old_email() get_def :old_email; end
  def self.new_name()  get_def :new_name;  end
  def self.new_email() get_def :new_email; end
  def self.repo_url()  get_def :repo_url;  end
  def self.work_dir()  get_def :work_dir;  end

  # Iterate the option definitions
  def self.each
    @option_defs.each do |option|
      yield option
    end
  end
end


# Basically a wrapper class around OptionParser.
class FixAuthorCLI
  def initialize
    # Default option values
    @options = {AllCLIOptions::work_dir.param_key => DefaultWorkDir}
  end

  private def create_parser
    OptionParser.new do |opts|
      opts.banner = get_optparse_banner

      AllCLIOptions::each do |key, opt|
        opts.on(opt.short_name, opt.long_name, opt.description)
      end
    end
  end

  def parse(args)
    option_parser = create_parser

    begin
      option_parser.parse(args, into: @options)
    rescue OptionParser::InvalidOption => opt_err
      puts "#{opt_err.message}\n".red
      puts option_parser.help
      exit 1
    end

    @options
  end

  def get_optparse_banner()
  "
Fix author name and email in a git repo.

Usage: #{File.basename($PROGRAM_NAME)} [options]
"
  end
end


class AuthorFixer

  def initialize(old_name:, old_email:, new_name:, new_email:, repo_url:, work_dir:)
    @old_name  = old_name
    @old_email = old_email
    @new_name  = new_name
    @new_email = new_email
    @repo_url  = repo_url
    @work_dir  = work_dir
  end

  def run()
    # match hidden dot folders by default
    glob_opts = File::FNM_DOTMATCH

    Dir.chdir(@work_dir) do
=begin
# Shell command example of workflow.

git clone git@ghblit:blitterated/tarmux.git
cd tarmux
git filter-repo --force --mailmap ../mailmap
git push -u --force origin git@ghblit:blitterated/tarmux.git
git remote add origin git@ghblit:blitterated/tarmux.git
=end
    end
  end

  def tar_folders(folders)
    folders.each do |f|
      tar_cmd = %(tar -I 'gzip -9' cvf "#{@work_dir}/#{f}.tgz" "#{f}")

      if block_given?
        yield(tar_cmd)
      else
        run_shell_command(tar_cmd)
      end
    end
  end

  def run_shell_command(shell_cmd)
    Open3.popen3("bash") do | stdin, stdout, stderr, wait_thread |

      stdout_thr = Thread.new { stdout.each {|line| puts line } }
      stderr_thr = Thread.new { stderr.each {|line| puts line.red } }

      stdin.puts(shell_cmd)

      wait_thread.value
    end
  end
end


def debug_dump
  puts "script name: #{File.basename(__FILE__)}"; puts

  puts "Ruby version: #{`ruby -v`}"; puts

  #repo_url = "git@ghblit:blitterated/tarmux.git"
  repo_url = "git@ghblit:blitterated/tarmux.wiki.git"
  puts "repo_url: #{repo_url}"; puts

  repo_name = repo_url.split('/')[-1].delete_suffix(".git")
  puts "repo_name: #{repo_name}"; puts

  proto_opts = AllCLIOptions::proto_option_defs
  p proto_opts; puts

  AllCLIOptions::each { |opt| p opt; puts }

  arg_options = FixAuthorCLI.new.parse ARGV
  p arg_options

=begin
  # Test CLIOption immutability
  AllCLIOptions::each do |key, opt|
    desc = opt.description
    desc.replace("#{key.to_s}: fart")
  end

  AllCLIOptions::each { |key, opt| puts opt.description }; puts
=end
end


debug_dump


=begin
ruby fix_author.rb --old-name "Ren Höek" --old-email "ren@nick.tv" --new-name "Stimpson J. Cat" --new-email "stimpy@nick.tv" --repo-url "git@github.com:stimpyj/spacemadness.git"
ruby fix_author.rb --old-name "Ren Höek" --old-email "ren@nick.tv" --new-name "Stimpson J. Cat" --new-email "stimpy@nick.tv" --repo-url "git@github.com:stimpyj/spacemadness.git" --work-dir "~/foo/bar"
=end
