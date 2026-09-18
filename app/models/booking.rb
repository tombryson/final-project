class Booking < ApplicationRecord
    belongs_to :user
    belongs_to :flight

    validates :rows, numericality: { only_integer: true, greater_than: 0 }
    validates :cols, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
    validate :seat_inside_plane

    private

    def seat_inside_plane
        return unless flight && rows && cols

        if rows > flight.plane.rows || cols >= flight.plane.cols
            errors.add(:base, 'Choose a seat inside this plane.')
        end
    end
end
