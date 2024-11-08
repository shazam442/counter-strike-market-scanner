WEAR_LEVELS = {
  (0.00..0.07) => "Factory New",
  (0.07..0.15) => "Minimal Wear",
  (0.15..0.38) => "Field-Tested",
  (0.38..0.45) => "Well-Worn",
  (0.45..1.00) => "Battle-Scarred"
}

module FloatHelper
  def float_range_to_wear_levels(min_wear, max_wear)
    selected_wear_levels = []

    WEAR_LEVELS.each do |range, title|
      # Check if the ranges overlap
      if range.cover?(min_wear) || range.cover?(max_wear) || (min_wear <= range.begin && max_wear >= range.end)
        selected_wear_levels << title
      end
    end

    selected_wear_levels
  end
end