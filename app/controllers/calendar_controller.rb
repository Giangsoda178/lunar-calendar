# frozen_string_literal: true

class CalendarController < InertiaController
  skip_before_action :authenticate
  def index
  end
end
