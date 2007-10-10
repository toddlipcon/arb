module DiffHelper

  def line_classes(line)
    classes = []

    classes << 'inserted' if line.appears_in_output? && line.fully_inserted?
    classes << 'deleted' if !line.appears_in_output?
    return classes
  end

end
