
class Rubinius::Backtrace
  def self.backtrace locations
    ::Myco::Backtrace.new(locations || [Rubinius::Location::Missing.new])
  end
end


class Myco::Backtrace < Rubinius::Backtrace
  def initialize(*)
    super
    @gem_color = "\033[0;36m"
    @gem_paths = [Rubinius::GEMS_PATH, Rubinius::RUNTIME_PATH]
  end
  
  def show(sep="\n", show_color=true)
    show_color &&= @colorize
    clear = show_color ? "\033[0m" : ""
    bold  = show_color ? "\033[1m" : ""
    sbullet = "{"
    ebullet = "}"
    
    @locations.map do |loc|
      file = (loc.position(Dir.getwd) || "").sub /(\:\d+)$/, ' \1'
      color = show_color ? color_from_loc(file, false) : ""
      color = @gem_color if try_gem_path file
      file_width = file.length + 1 + sbullet.length
      
      place = loc.instance_variable_get(:@method_module).to_s + '#'
      place += loc.method.name.to_s
      place_width = place.length + 1 + ebullet.length
      
      padding = @width - file_width - place_width
      padding += @width until padding >= 0
      
      file_line  = bold + color + sbullet + ' ' + clear + color + file
      place_line = color + bold + place + ' ' + ebullet + clear
      
      output = file_line + ' '*padding + place_line
      output = nil if file == "(myco_internal) :1"
      output
    end.compact.reverse.join sep
  end
  
  # If file is in one of the GEM_PATHs, mutate the string and return true
  def try_gem_path file
    @gem_paths.each do |gem_path|
      if file.start_with? gem_path and not gem_path.empty?
        file.sub! File.join(gem_path, 'gems'), ''
        file.sub! %r{/[^/]*/}, ''
        return true
      end
    end
    return false
  end
end
