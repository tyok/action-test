class ActionFormatter < RuboCop::Formatter::ProgressFormatter
  def report_file(file, offenses)
    action_formatter_group_offenses(file, offenses) { super }
  end

  def report_offense(file, offense)
    output.printf(
      "%<path>s:%<line>d:%<column>d:\n%<severity>s: %<message>s\n",
      path: cyan(smart_path(file)),
      line: offense.line,
      column: offense.real_column,
      severity: colored_severity_code(offense),
      message: action_formatter_fix_missing_cop_name(message(offense)),
    )

    begin
      return output.puts("") unless valid_line?(offense)

      action_formatter_report_line_with_highlight(offense)
      output.puts("")
    rescue IndexError
      # range is not on a valid line; perhaps the source file is empty
    end
  end

  def action_formatter_group_offenses(file, offenses)
    count = offenses.count

    output.printf("::error::%<path>s\n", path: smart_path(file))

    return yield if count < 3

    counts = offenses.group_by { |o| o.severity.name }.transform_values(&:count)
    count_labels = COLOR_FOR_SEVERITY.to_a.reverse.map do |severity, severity_color|
      count = counts[severity]
      next unless count
      colorize("#{count} #{severity.to_s}", severity_color)
    end

    output.printf("::group::%s\n", "Click to see #{count_labels.compact.join(", ")} offenses")
    yield
    output.puts("::endgroup::")
  end

  def action_formatter_report_line_with_highlight(offense)
    severity_color = COLOR_FOR_SEVERITY[offense.severity.name]
    location = offense.location
    highlighted_area = offense.highlighted_area

    hard_limit = 78
    limit = hard_limit - ELLIPSES.length
    preview = 20
    ellipses = yellow(ELLIPSES)
    source_line = location.source_line
    h_start = highlighted_area.begin_pos
    h_size = highlighted_area.size

    source_line[h_start, h_size].each_char.each_with_index do |char, index|
      source_line[h_start + index] = "·" if char == " "
    end

    if h_start + h_size < source_line.length && hard_limit < source_line.length
      limit = h_start + h_size if limit < h_start + h_size
      source_line = source_line[0, limit] + ellipses
    end

    snippet =
      source_line[0...h_start] +
      rainbow.wrap(source_line[h_start, h_size]).bg(severity_color).fg(:black) +
      source_line[h_start + h_size..-1]

    snippet << " " << ellipses if location.first_line != location.last_line

    output.puts("# #{snippet}")
  end

  def action_formatter_fix_missing_cop_name(message)
    message.gsub(/\A(.*): /, "masa sih ")
  end
end
