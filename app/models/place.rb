class Place < ApplicationRecord
  # Enum for place types
  enum :kind, { unknown: 0, city: 1, landmark: 2, region: 3 }, prefix: true

  belongs_to :parent, class_name: "Place", optional: true
  has_many :children, class_name: "Place", foreign_key: "parent_id"
end
