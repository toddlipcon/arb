module DiffHelper

  def line_classes(line)
    classes = []

    classes << 'inserted' if line.appears_in_output? && line.fully_inserted?
    classes << 'deleted' if !line.appears_in_output?
    return classes
  end

  def extended_headers_to_display(file_change_set)
    display_keys = [
      'old mode',
      'new mode',
      'copy from',
      'copy to',
      'rename from',
      'rename to',
      'similarity index',
      'dissimilarity index'
    ];

    file_change_set.extended_headers.select do |key, val|
      display_keys.include?(key)
    end
  end

end
