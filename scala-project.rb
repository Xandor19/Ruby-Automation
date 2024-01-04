# frozen_string_literal: true

require 'fileutils'
require_relative 'utils'
require_relative 'cl_param'

def main(gitignore_content)
  dest_path = get_param(CLParam.new('dir', 'd'), true, validate_path) do
    path = Dir.pwd
    puts "Using current working dir #{path} as no path was specified"
    path
  end

  proj_name = get_param(CLParam.new('name', 'n'), true, validate_name) do
    if interactive_terminal?
      print 'Input project name: '
      validate_name.call(STDIN.gets.chomp)
    else
      exit_with_err('Project name must be provided when calling from another process', -1)
    end
  end

  sbt = get_param(CLParam.new('sbt', 'b'), true, validate_sbt) do
    ver = require_from_env('sbt', '--script-version', false).chomp
    exit_with_err("No sbt was found on system, version cannot be established", -1) if ver.empty?
    puts "Using system sbt version (#{ver})"
    ver
  end

  scala = get_param(CLParam.new('scala', 's'), true, validate_scala) do
    require_from_env('scala', '--version', true) do |out, err|
      ver = err.scan(/[0-9]+[.][0-9]+[.][0-9]+/).first
      exit_with_err("No Scala was found on system, version cannot be established", -1) if ver.empty?
      puts "Using system Scala version (#{ver})"
      ver
    end
  end

  gitignore = ARGV.include?('--no-git') ? '' : get_param(CLParam.new('git-ignore', 'i'), true, validate_gitig(gitignore_content)) do
    if interactive_terminal?
      predefined = gitignore_content.keys
      pred_str = predefined.reduce {|a, b| a + '/' + b}
      negation = %w[n N no No NO]

      print "No gitignore template was found, do you wish to add one of the predefined (#{pred_str}/no)? "
      choice = STDIN.gets.chomp

      until predefined.include?(choice) || negation.include?(choice)
        print "Invalid choice, select one or the available templates (#{pred_str}) or 'no'"
        choice = STDIN.gets.chomp
      end
      negation.include?(choice) ? '' : choice
    else
      ''
    end
  end

  proj_path = File.join(dest_path, proj_name)
  FileUtils.mkdir_p proj_path
  Dir.chdir proj_path

  %w[main test].each do |folder|
    %w[scala resources].each { |pack| FileUtils.mkdir_p "./src/#{folder}/#{pack}"}
  end

  Dir.mkdir('project')
  File.open('project/build.properties', 'w') { |f| f.write "sbt-version=#{sbt}\n" }

  File.open('./build.sbt', 'w') do |f|
    f.write "name := \"#{proj_name}\"\n"
    f.write "version := \"0.1.0\"\n"
    f.write "scalaVersion := \"#{scala}\"\n"
  end

  unless gitignore.empty?
    File.open('./.gitignore', 'w') do |f|
      gitignore_content[gitignore].each { |ig| f.write(ig + "\n")}
      f.write "project/project/\n"
      f.write "project/target/\n"
      f.write "target/\n"
      f.write "out/\n"
    end
  end
end

def validate_path
  lambda do |path|
    exit_with_err('Path cannot be empty nor contain spaces', -1) if path.empty? || path.include?(' ')
    path
  end
end

def validate_name
  lambda do |name|
    exit_with_err('Name cannot be empty nor contain spaces', -1) if name.empty? || name.include?(' ')
    name
  end
end

def validate_sbt
  lambda { |sbt| sbt}
end

def validate_scala
  lambda { |sc| sc}
end

def validate_gitig(content)
  lambda do |choice|
    exit_with_err("Selected template (#{choice}) doest not exist or isn't supported yet", -1) unless content.include? choice
    content[choice]
  end
end

gitignore_content = {
  'idea' => %w[.idea/],
  'code' => %w[.bsp/, .bloop/, .metals/, .vscode/ project/.bloop]
}

main(gitignore_content)


