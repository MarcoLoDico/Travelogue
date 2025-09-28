class Place < ApplicationRecord
  belongs_to :parent, class_name: 'Place', optional: true
  has_many :children, class_name: 'Place', foreign_key: 'parent_id'
end
