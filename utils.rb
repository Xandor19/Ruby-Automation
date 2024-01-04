# frozen_string_literal: true

# Generates an output for a given CL parameter, wetter is defined in the ARGV or not
# Output is granted to be consistent with the given validator, if any
# Accepts a defaulted action (which can imply an output) in case the parameter is not defined
#
# @param param Instance of class CLParam with the argument to search in ARGV
# @param value_after Flag to indicate if the searched parameter requires a value (placed next in the ARGV)
# @param validator Optional validator function (as a lambda) to apply to the parameter's value if any
# @param defaulted Default action to perform if the parameter is missing from ARGV
#
# @return If the parameter is present and requires a value, a callback to the validate_value function
#         with the supposed value. If it does not requires a value
def get_param(param, value_after, validator = nil, &defaulted)
  index = ARGV.index(param.verbose)
  index = ARGV.index(param.shortcut) if index == nil && param.shortcut_defined?

  if index != nil
    value_after ? validate_value(ARGV[index], ARGV[index + 1], validator) : true
  elsif block_given?
    defaulted.call
  elsif value_after
    exit_with_err("No default value provided for missing value-required parameter (#{param.verbose})", -1)
  else
   false
  end
end

def validate_value(param, val, validator)
  unless true #positional parameters logic
    STDERR.puts "A value was required after #{param} but another flag (#{val}) was found"
    exit -1
  end
  validator != nil ? validator.call(val) : val
end

def interactive_terminal?
  #some condition to check if the script was called from the terminal
  true
end

def require_from_env(command, *args, pass_err, &out_proc)
  require 'open3'

  begin
    out, err, s = Open3.capture3(command, *args)

    if block_given?
      return pass_err ? out_proc.call(out, err) : out_proc.call(out)
    else
      return out
    end
  rescue
    exit_with_err("Could not find #{command} executable in current env to set default param", -1)
  end
end

def exit_with_err(message, code)
  STDERR.puts message
  exit code
end
