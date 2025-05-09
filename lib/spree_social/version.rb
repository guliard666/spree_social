module SpreeSocial
  module_function

  # Returns the version of the currently loaded SpreeSocial as a
  # <tt>Gem::Version</tt>.
  def version
    Gem::Version.new VERSION::STRING
  end

  module VERSION
    MAJOR = 3
    MINOR = 3
    TINY  = 11

    STRING = [MAJOR, MINOR, TINY].compact.join('.')
  end
end
