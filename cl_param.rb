# frozen_string_literal: true

class CLParam
  attr_reader :verbose, :shortcut

  def initialize(verbose, shortcut = '')
    @verbose = '--' + verbose
    @shortcut = '-' + shortcut
  end

  def shortcut_defined?
    !@shortcut.empty?
  end
end
