class Boooking < ApplicationRecord
    belongs_to :user
    belongs_to :flight
end
