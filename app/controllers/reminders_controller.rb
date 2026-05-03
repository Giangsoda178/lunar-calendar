# frozen_string_literal: true

class RemindersController < InertiaController
  before_action :set_reminder, only: %i[show edit update destroy]

  def index
    reminders = Current.user.reminders.order(start: :asc)
    render inertia: {
      reminders: reminders,
      today: Date.today.iso8601
    }
  end

  def show
    render inertia: {reminder: @reminder}
  end

  def new
    @reminder = Current.user.reminders.new
    render inertia: {reminder: @reminder}
  end

  def create
    @reminder = Current.user.reminders.new(reminder_params)
    if @reminder.save
      redirect_to calendar_index_path, notice: "Reminder created successfully"
    else
      redirect_to new_reminder_path, alert: "Failed to create reminder", inertia: inertia_errors(@reminder)
    end
  end

  def edit
    render inertia: {reminder: @reminder}
  end

  def update
    if @reminder.update(reminder_params)
      redirect_to calendar_index_path, notice: "Reminder updated successfully"
    else
      redirect_to edit_reminder_path(@reminder), alert: "Failed to update reminder", inertia: inertia_errors(@reminder)
    end
  end

  def destroy
    @reminder.discard!
    if request.headers["X-Inertia"]
      location = request.referer || request.original_url
      response.set_header("X-Inertia-Location", location)
      head :conflict
    else
      redirect_to reminders_path, notice: "Reminder deleted successfully"
    end
  end

  private

  def set_reminder
    @reminder = Current.user.reminders.find(params[:id])
  end

  def reminder_params
    params.expect(reminder: [:title, :notes, :start, :end, :is_lunar, :alert, :alert_minutes, :repeat, :repeat_period, :repeat_ends_at])
  end
end
